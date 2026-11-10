import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Standalone Google authentication service (google_sign_in v6 API).
///
/// [GoogleSignIn.signIn] returns null when the user cancels — the caller
/// should check for [GoogleSignInCancelledException] and show a message
/// rather than treating cancellation as a login error.
///
/// On first sign-in a patient profile is written to Firestore.
/// On subsequent sign-ins the existing record is left unchanged.
/// Role is always 'patient' — staff/admin must be provisioned by an admin.
class GoogleAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Reuse a single GoogleSignIn instance across calls
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Authenticate with Google and return a [UserCredential].
  ///
  /// Throws [GoogleSignInCancelledException] when the user dismisses the
  /// account picker without selecting an account.
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      // signIn() returns null when the user cancels the picker
      if (googleUser == null) {
        throw GoogleSignInCancelledException();
      }

      // Exchange Google credentials for a Firebase credential
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Authenticate with Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _ensureFirestoreProfile(user, googleUser.email);
      }

      return userCredential;
    } on GoogleSignInCancelledException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('[GoogleAuthService] FirebaseAuth error: ${e.code} — ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[GoogleAuthService] Unexpected error: $e');
      rethrow;
    }
  }

  /// Write a patient profile to Firestore only when this is a new account.
  Future<void> _ensureFirestoreProfile(User user, String googleEmail) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    // Existing account — do not overwrite role or any other field
    if (userDoc.exists) return;

    // New account — create a patient record using snake_case field names
    // to match the existing UserModel.fromMap() convention
    await userRef.set({
      'uid': user.uid,
      'full_name': user.displayName ?? '',
      'email': user.email ?? googleEmail,
      'phone_number': user.phoneNumber ?? '',
      'photo_url': user.photoURL ?? '',
      // Role is always 'patient' for public Google sign-in.
      // Staff and admin accounts must be provisioned by an administrator.
      'role': 'patient',
      'is_active': true,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Also create the companion patients/ profile document
    final patientRef = _firestore.collection('patients').doc(user.uid);
    await patientRef.set({
      'uid': user.uid,
      'full_name': user.displayName ?? '',
      'email': user.email ?? googleEmail,
      'phone_number': user.phoneNumber ?? '',
      'photo_url': user.photoURL ?? '',
      'created_at': FieldValue.serverTimestamp(),
    });

    debugPrint('[GoogleAuthService] New patient profile created for ${user.uid}');
  }

  /// Sign out of both Firebase and Google.
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Not signed in via Google — ignore
    }
  }
}

/// Thrown when the user cancels the Google account picker.
class GoogleSignInCancelledException implements Exception {
  @override
  String toString() => 'Google sign-in was cancelled.';
}
