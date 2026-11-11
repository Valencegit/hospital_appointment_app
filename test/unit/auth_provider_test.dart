import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
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
  Future<void> sendPasswordResetEmail(String email) async {}

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
  group('AuthProvider', () {
    late MockAuthService mockAuth;
    late MockFirestoreService mockFirestore;

    setUp(() {
      mockAuth = MockAuthService();
      mockFirestore = MockFirestoreService();
    });

    tearDown(() {
      mockAuth.dispose();
    });

    test('starts unauthenticated and never invents a local session', () async {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      final result = await auth.signIn(
        email: 'admin@example.com',
        password: 'password123',
      );

      expect(result, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.errorMessage, contains('offline'));
    });

    test('signOut clears session state', () async {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );

      await auth.signOut();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
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
