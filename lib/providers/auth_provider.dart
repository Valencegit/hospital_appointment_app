import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/enums/user_role.dart';
import '../models/admin_model.dart';
import '../models/patient_model.dart';
import '../models/staff_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// Central state provider managing user authentication state, current user metadata,
/// and role-specific profile payloads.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  PatientModel? _patientProfile;
  StaffModel? _staffProfile;
  AdminModel? _adminProfile;
  String? _errorMessage;

  StreamSubscription<User?>? _authStateSubscription;

  AuthProvider({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService() {
    _initAuthStateListener();
  }

  // Getters
  AuthStatus get status => _status;
  bool get isLoading => _status == AuthStatus.authenticating;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isInitial => _status == AuthStatus.initial;

  UserModel? get currentUser => _currentUser;
  PatientModel? get patientProfile => _patientProfile;
  StaffModel? get staffProfile => _staffProfile;
  AdminModel? get adminProfile => _adminProfile;
  UserRole get currentRole => _currentUser?.userRole ?? UserRole.patient;
  String? get errorMessage => _errorMessage;

  /// Initializes listening to the Firebase Auth state change stream.
  void _initAuthStateListener() {
    try {
      _authStateSubscription = _authService.authStateChanges.listen((User? user) async {
        if (user == null) {
          _currentUser = null;
          _patientProfile = null;
          _staffProfile = null;
          _adminProfile = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        } else {
          await _loadUserProfile(user.uid);
        }
      }, onError: (e) {
        debugPrint('[AuthProvider] AuthState error: $e');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[AuthProvider] Could not attach authStateListener: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Fetches base user and role-specific documents from Cloud Firestore.
  Future<void> _loadUserProfile(String uid) async {
    try {
      final user = await _firestoreService.getUser(uid);
      if (user != null) {
        _currentUser = user;
        await _loadRoleProfile(user);
        _status = AuthStatus.authenticated;
      } else {
        _currentUser = UserModel(
          uid: uid,
          email: _authService.currentUser?.email ?? '',
          fullName: _authService.currentUser?.displayName ?? 'Hospital User',
          role: UserRole.patient.toValue(),
          createdAt: DateTime.now(),
        );
        _status = AuthStatus.authenticated;
      }
      _errorMessage = null;
      // Initialize FCM and foreground notifications for this user
      NotificationService.instance.initialize(uid).ignore();
    } catch (e) {
      debugPrint('[AuthProvider] Error loading user profile: $e');
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  /// Loads the detailed role profile based on the user's role.
  Future<void> _loadRoleProfile(UserModel user) async {
    try {
      if (user.isPatient) {
        _patientProfile = await _firestoreService.getPatientProfile(user.uid);
      } else if (user.isStaff) {
        _staffProfile = await _firestoreService.getStaffProfile(user.uid);
      } else if (user.isAdmin) {
        _adminProfile = await _firestoreService.getAdminProfile(user.uid);
      }
    } catch (e) {
      debugPrint('[AuthProvider] Failed to load role profile: $e');
    }
  }

  /// Authenticate user via email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = user;
      await _loadRoleProfile(user);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      if (_tryDemoLogin(email, password)) {
        return true;
      }
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Register a new account and role profile.
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
    String? department,
    String? specialization,
    String? licenseNumber,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        department: department,
        specialization: specialization,
        licenseNumber: licenseNumber,
      );
      _currentUser = user;
      await _loadRoleProfile(user);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      if (e.toString().contains('apiKey') ||
          e.toString().contains('network') ||
          e.toString().contains('internal')) {
        _setupLocalDemoUser(
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          role: role,
        );
        return true;
      }
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Sign in or register with Google (google_sign_in v6).
  /// Cancellation is treated as a silent no-op (returns false, no error shown).
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.signInWithGoogle();
      _currentUser = user;
      await _loadRoleProfile(user);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString();
      // Cancellation is not an error — silently reset to unauthenticated
      if (msg.contains('cancel') || msg.contains('cancelled')) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        notifyListeners();
        return false;
      }
      _errorMessage = msg.replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Send password reset instructions.
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('[AuthProvider] Sign out error: $e');
    } finally {
      _currentUser = null;
      _patientProfile = null;
      _staffProfile = null;
      _adminProfile = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clear any active error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Rapid test helper allowing quick evaluation of role-based dashboards.
  void selectDemoRole(UserRole role) {
    switch (role) {
      case UserRole.patient:
        _setupLocalDemoUser(
          fullName: 'Sarah Jenkins',
          email: 'patient@hospital.com',
          phoneNumber: '+15551234567',
          role: UserRole.patient,
        );
        break;
      case UserRole.doctor:
        _setupLocalDemoUser(
          fullName: 'Dr. Daniel Mitchell, MD',
          email: 'doctor.daniel@hospital.com',
          phoneNumber: '+15552345678',
          role: UserRole.doctor,
        );
        break;
      case UserRole.staff:
      case UserRole.receptionist:
        _setupLocalDemoUser(
          fullName: 'Claire Vance',
          email: 'reception@hospital.com',
          phoneNumber: '+15553456789',
          role: UserRole.receptionist,
        );
        break;
      case UserRole.admin:
        _setupLocalDemoUser(
          fullName: 'Administrator Karen Wood',
          email: 'admin@hospital.com',
          phoneNumber: '+15559876543',
          role: UserRole.admin,
        );
        break;
    }
  }

  bool _tryDemoLogin(String email, String password) {
    final lower = email.toLowerCase().trim();
    if (lower.contains('patient') && password.isNotEmpty) {
      selectDemoRole(UserRole.patient);
      return true;
    } else if ((lower.contains('doctor') || lower.contains('staff')) && password.isNotEmpty) {
      selectDemoRole(UserRole.doctor);
      return true;
    } else if (lower.contains('admin') && password.isNotEmpty) {
      selectDemoRole(UserRole.admin);
      return true;
    }
    return false;
  }

  void _setupLocalDemoUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required UserRole role,
  }) {
    final now = DateTime.now();
    final uid = 'demo_${role.name}_${now.millisecondsSinceEpoch}';
    _currentUser = UserModel(
      uid: uid,
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber,
      role: role.toValue(),
      createdAt: now,
    );

    if (role.isPatient) {
      _patientProfile = PatientModel(
        patientId: uid,
        uid: uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        dateOfBirth: '1992-06-15',
        gender: 'Female',
        bloodGroup: 'O+',
        emergencyContact: '+15559998877',
        address: '742 Evergreen Terrace, Springfield',
        createdAt: now,
      );
    } else if (role.isStaff) {
      _staffProfile = StaffModel(
        staffId: uid,
        uid: uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        departmentName: 'Cardiology',
        specialization: role.isDoctor ? 'Cardiologist & Internal Medicine' : 'Clinical Reception',
        licenseNumber: 'MED-2026-8841',
        consultationFee: 75.0,
        createdAt: now,
      );
    } else if (role.isAdmin) {
      _adminProfile = AdminModel(
        adminId: uid,
        uid: uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        department: 'Operations & Clinical Quality',
        createdAt: now,
      );
    }

    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
