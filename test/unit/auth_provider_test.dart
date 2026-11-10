import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:appointmentapp/core/enums/user_role.dart';
import 'package:appointmentapp/models/user_model.dart';
import 'package:appointmentapp/providers/auth_provider.dart';
import 'package:appointmentapp/services/auth_service.dart';
import 'package:appointmentapp/services/firestore_service.dart';

class MockAuthService extends Fake implements AuthService {
  final _controller = StreamController<User?>.broadcast();

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => null;

  @override
  Future<void> signOut() async {
    _controller.add(null);
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw Exception('Firebase connection offline');
  }

  void dispose() {
    _controller.close();
  }
}

class MockFirestoreService extends Fake implements FirestoreService {}

void main() {
  group('AuthProvider Unit Tests', () {
    late MockAuthService mockAuth;
    late MockFirestoreService mockFirestore;

    setUp(() {
      mockAuth = MockAuthService();
      mockFirestore = MockFirestoreService();
    });

    tearDown(() {
      mockAuth.dispose();
    });

    test('Initial state is unauthenticated or initial', () {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('selectDemoRole properly creates and configures patient profile', () {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      auth.selectDemoRole(UserRole.patient);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentRole, UserRole.patient);
      expect(auth.currentUser?.email, 'patient@hospital.com');
      expect(auth.patientProfile, isNotNull);
      expect(auth.patientProfile?.fullName, 'Sarah Jenkins');
      expect(auth.patientProfile?.bloodGroup, 'O+');
      expect(auth.staffProfile, isNull);
      expect(auth.adminProfile, isNull);
    });

    test('selectDemoRole properly creates and configures doctor profile', () {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      auth.selectDemoRole(UserRole.doctor);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentRole, UserRole.doctor);
      expect(auth.currentUser?.email, 'doctor.daniel@hospital.com');
      expect(auth.staffProfile, isNotNull);
      expect(auth.staffProfile?.role, UserRole.doctor);
      expect(auth.staffProfile?.departmentName, 'Cardiology');
      expect(auth.patientProfile, isNull);
      expect(auth.adminProfile, isNull);
    });

    test('selectDemoRole properly creates and configures admin profile', () {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      auth.selectDemoRole(UserRole.admin);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentRole, UserRole.admin);
      expect(auth.currentUser?.email, 'admin@hospital.com');
      expect(auth.adminProfile, isNotNull);
      expect(auth.adminProfile?.department, 'Operations & Clinical Quality');
      expect(auth.patientProfile, isNull);
      expect(auth.staffProfile, isNull);
    });

    test('selectDemoRole properly creates staff/receptionist profile', () {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      auth.selectDemoRole(UserRole.receptionist);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentRole, UserRole.receptionist);
      expect(auth.staffProfile, isNotNull);
      expect(auth.staffProfile?.role, UserRole.receptionist);
    });

    test('Demo login fallback recognizes patient, doctor, and admin keywords', () async {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );

      // Patient sign in fallback
      final patientResult = await auth.signIn(
        email: 'demo.patient@hospital.com',
        password: 'password123',
      );
      expect(patientResult, isTrue);
      expect(auth.currentRole, UserRole.patient);

      // Doctor sign in fallback
      final docResult = await auth.signIn(
        email: 'staff.doctor@hospital.com',
        password: 'password123',
      );
      expect(docResult, isTrue);
      expect(auth.currentRole, UserRole.doctor);

      // Admin sign in fallback
      final adminResult = await auth.signIn(
        email: 'system.admin@hospital.com',
        password: 'password123',
      );
      expect(adminResult, isTrue);
      expect(auth.currentRole, UserRole.admin);
    });

    test('signOut clears authenticated session state', () async {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      auth.selectDemoRole(UserRole.patient);
      expect(auth.isAuthenticated, isTrue);

      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.patientProfile, isNull);
      expect(auth.status, AuthStatus.unauthenticated);
    });

    test('clearError resets errorMessage', () {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      auth.clearError();
      expect(auth.errorMessage, isNull);
    });
  });
}
