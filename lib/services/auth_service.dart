import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/enums/user_role.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Authentication service interacting with Firebase Authentication.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirestoreService _firestoreService;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirestoreService? firestoreService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Currently logged in Firebase User.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Current user UID.
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  /// Sign in using email and password.
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const FormatException(AppConstants.errAuthFailed);
      }

      final userModel = await _firestoreService.getUser(user.uid);
      if (userModel == null) {
        throw Exception('User record not found in hospital database.');
      }

      if (!userModel.isActive) {
        await signOut();
        throw Exception('Your account has been deactivated. Please contact administrator.');
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      debugPrint('[AuthService] Sign in error: $e');
      rethrow;
    }
  }

  /// Register a new user with corresponding Firestore records.
  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
    String? department,
    String? specialization,
    String? licenseNumber,
  }) async {
    User? createdUser;
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const FormatException(AppConstants.errAuthFailed);
      }
      createdUser = user;

      await user.updateDisplayName(fullName.trim());

      final now = DateTime.now();
      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        role: role.toValue(),
        photoUrl: user.photoURL,
        isActive: true,
        createdAt: now,
      );

      await _firestoreService.createUser(userModel);

      if (role.isPatient) {
        await _firestoreService.createPatientProfile(
          uid: user.uid,
          fullName: fullName.trim(),
          email: email.trim(),
          phoneNumber: phoneNumber.trim(),
        );
      } else if (role.isStaff) {
        await _firestoreService.createStaffProfile(
          uid: user.uid,
          fullName: fullName.trim(),
          email: email.trim(),
          phoneNumber: phoneNumber.trim(),
          role: role,
          departmentName: department ?? 'General Medicine',
          specialization: specialization ?? (role.isDoctor ? 'General Practitioner' : 'Medical Staff'),
          licenseNumber: licenseNumber ?? '',
        );
      } else if (role.isAdmin) {
        await _firestoreService.createAdminProfile(
          uid: user.uid,
          fullName: fullName.trim(),
          email: email.trim(),
          phoneNumber: phoneNumber.trim(),
          department: department ?? 'Hospital Administration',
        );
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      debugPrint('[AuthService] Registration error: $e');
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (cleanupError) {
          debugPrint(
            '[AuthService] Could not remove incomplete registration: $cleanupError',
          );
        }
      }
      rethrow;
    }
  }

  /// Send password reset link to user email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      debugPrint('[AuthService] Reset password error: $e');
      rethrow;
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      // Also sign out of Google so the account picker shows next time
      try {
        await GoogleSignIn().signOut();
      } catch (_) {
        // Not signed in via Google — ignore
      }
    } catch (e) {
      debugPrint('[AuthService] Sign out error: $e');
      rethrow;
    }
  }

  /// Sign in or register with Google (google_sign_in v6 API).
  ///
  /// [GoogleSignIn.signIn] returns null when the user cancels the picker,
  /// which is treated as a clean cancellation, not an error.
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception(AppConstants.errAuthFailed);

      // Check if this user already has a Firestore record
      final existing = await _firestoreService.getUser(user.uid);
      if (existing != null) {
        if (!existing.isActive) {
          await signOut();
          throw Exception(
              'Your account has been deactivated. Please contact administrator.');
        }
        return existing;
      }

      // First-time Google sign-in — create patient profile
      final now = DateTime.now();
      final fullName = user.displayName ?? googleUser.displayName ?? '';
      final email = user.email ?? googleUser.email;

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        fullName: fullName,
        phoneNumber: user.phoneNumber ?? '',
        role: UserRole.patient.toValue(),
        photoUrl: user.photoURL,
        isActive: true,
        createdAt: now,
      );

      await _firestoreService.createUser(userModel);
      await _firestoreService.createPatientProfile(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phoneNumber: user.phoneNumber ?? '',
      );

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      debugPrint('[AuthService] Google sign-in error: $e');
      rethrow;
    }
  }

  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = AppConstants.errUserNotFound;
        break;
      case 'wrong-password':
      case 'invalid-credential':
        message = AppConstants.errWrongPassword;
        break;
      case 'email-already-in-use':
        message = AppConstants.errEmailInUse;
        break;
      case 'invalid-email':
        message = AppConstants.errInvalidEmail;
        break;
      case 'weak-password':
        message = AppConstants.errWeakPassword;
        break;
      case 'user-disabled':
        message = 'This account has been deactivated.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again shortly.';
        break;
      case 'network-request-failed':
        message = AppConstants.errNetwork;
        break;
      default:
        message = e.message ?? AppConstants.errGeneric;
    }
    return Exception(message);
  }
}
