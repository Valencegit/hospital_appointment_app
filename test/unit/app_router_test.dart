import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:appointmentapp/core/enums/user_role.dart';
import 'package:appointmentapp/core/routing/app_router.dart';
import 'package:appointmentapp/providers/auth_provider.dart';
import 'package:appointmentapp/services/auth_service.dart';
import 'package:appointmentapp/services/firestore_service.dart';

class MockAuthService extends Fake implements AuthService {
  final _controller = StreamController<User?>.broadcast();

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => null;

  void dispose() {
    _controller.close();
  }
}

class MockFirestoreService extends Fake implements FirestoreService {}

void main() {
  group('AppRouter & RBAC Access Control Tests', () {
    late MockAuthService mockAuth;
    late MockFirestoreService mockFirestore;

    setUp(() {
      mockAuth = MockAuthService();
      mockFirestore = MockFirestoreService();
    });

    tearDown(() {
      mockAuth.dispose();
    });

    test('Unauthenticated user is initialized with router instance', () {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      final appRouter = AppRouter(authProvider: auth);
      final router = appRouter.router;

      expect(router, isA<GoRouter>());
      expect(auth.isAuthenticated, isFalse);
    });

    test('each trusted role maps to its own dashboard', () {
      expect(AppRouter.dashboardForRole(UserRole.patient), '/patient');
      expect(
          AppRouter.dashboardForRole(UserRole.receptionist), '/receptionist');
      expect(AppRouter.dashboardForRole(UserRole.doctor), '/doctor');
      expect(
        AppRouter.dashboardForRole(UserRole.schedulingOfficer),
        '/scheduling',
      );
      expect(AppRouter.dashboardForRole(UserRole.admin), '/admin');
      expect(AppRouter.dashboardForRole(UserRole.pending), '/account-pending');
    });

    test('All main routes are configured in GoRouter route tree', () {
      final auth = AuthProvider(
        authService: mockAuth,
        firestoreService: mockFirestore,
      );
      final appRouter = AppRouter(authProvider: auth);
      final routes = appRouter.router.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();

      expect(routes, contains('/splash'));
      expect(routes, contains('/login'));
      expect(routes, contains('/register'));
      expect(routes, contains('/forgot-password'));
      expect(routes, contains('/patient'));
      expect(routes, contains('/patient/profile'));
      expect(routes, contains('/patient/departments'));
      expect(routes, contains('/patient/appointments'));
      expect(routes, contains('/patient/notifications'));
      expect(routes, contains('/staff'));
      expect(routes, contains('/staff/appointments'));
      expect(routes, contains('/staff/schedules'));
      expect(routes, contains('/staff/patients'));
      expect(routes, contains('/staff/notifications'));
      expect(routes, contains('/admin'));
      expect(routes, contains('/admin/users'));
      expect(routes, contains('/admin/users/create-staff'));
      expect(routes, contains('/admin/departments'));
      expect(routes, contains('/admin/reports'));
      expect(routes, contains('/admin/audit'));
      expect(routes, contains('/receptionist'));
      expect(routes, contains('/doctor'));
      expect(routes, contains('/scheduling'));
      expect(routes, contains('/account-pending'));
    });
  });
}
