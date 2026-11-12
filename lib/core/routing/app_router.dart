import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/account_pending_screen.dart';
import '../../features/splash/screens/splash_screen.dart';

// Patient
import '../../features/patient/screens/patient_dashboard_screen.dart';
import '../../features/patient/screens/patient_profile_screen.dart';
import '../../features/patient/screens/departments_screen.dart';
import '../../features/patient/screens/slots_screen.dart';
import '../../features/patient/screens/book_appointment_screen.dart';
import '../../features/patient/screens/booking_confirmation_screen.dart';
import '../../features/patient/screens/patient_appointments_screen.dart';
import '../../features/patient/screens/appointment_detail_screen.dart';
import '../../features/patient/screens/notifications_screen.dart';

// Staff
import '../../features/staff/screens/staff_appointments_screen.dart';
import '../../features/staff/screens/staff_appointment_detail_screen.dart';
import '../../features/staff/screens/manage_slots_screen.dart';
import '../../features/staff/screens/staff_patients_screen.dart';
import '../../features/staff/screens/role_dashboards.dart';

// Admin
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/create_staff_account_screen.dart';
import '../../features/admin/screens/manage_users_screen.dart';
import '../../features/admin/screens/manage_departments_screen.dart';
import '../../features/admin/screens/reports_screen.dart';
import '../../features/admin/screens/audit_logs_screen.dart';

import '../enums/user_role.dart';
import '../../providers/auth_provider.dart';

/// Centralized declarative router enforcing authentication states and
/// role-based access control for CarePulse Hospital.
class AppRouter {
  final AuthProvider authProvider;

  AppRouter({required this.authProvider});

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = authProvider.isAuthenticated;
      final isInitial = authProvider.isInitial;
      final loc = state.matchedLocation;

      // Keep splash until auth resolves
      if (isInitial && loc == '/splash') return null;

      final isAuthRoute = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/splash';

      // Unauthenticated users can only access auth routes
      if (!isAuth) return isAuthRoute ? null : '/login';

      // Authenticated users leaving auth screens → go to their dashboard
      if (isAuthRoute) return dashboardForRole(authProvider.currentRole);

      // Role-based access guards
      final role = authProvider.currentRole;
      if (loc.startsWith('/admin') && !role.isAdmin) {
        return dashboardForRole(role);
      }
      if ((loc.startsWith('/receptionist') && !role.isReceptionist) ||
          (loc.startsWith('/doctor') && !role.isDoctor) ||
          (loc.startsWith('/scheduling') && !role.isSchedulingOfficer)) {
        return dashboardForRole(role);
      }
      if (loc == '/staff' || loc == '/staff-home') {
        return dashboardForRole(role);
      }
      if ((loc == '/staff/appointments' ||
              loc.startsWith('/staff/appointments/')) &&
          !role.isReceptionist &&
          !role.isDoctor &&
          !role.isAdmin) {
        return dashboardForRole(role);
      }
      if (loc.startsWith('/staff/schedules') &&
          !role.isSchedulingOfficer &&
          !role.isAdmin &&
          !role.isDoctor) {
        return dashboardForRole(role);
      }
      if (loc.startsWith('/staff/patients') &&
          !role.isReceptionist &&
          !role.isAdmin) {
        return dashboardForRole(role);
      }
      if (loc.startsWith('/staff/reports') && !role.isAdmin) {
        return dashboardForRole(role);
      }
      if (loc.startsWith('/patient') && !role.isPatient) {
        return dashboardForRole(role);
      }

      return null;
    },
    routes: [
      // ── Auth & Splash ──────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/account-pending',
        builder: (_, __) => const AccountPendingScreen(),
      ),

      // ── Patient ────────────────────────────────────────────────────────
      GoRoute(
        path: '/patient',
        builder: (_, __) => const PatientDashboardScreen(),
      ),
      GoRoute(
        path: '/patient-home',
        redirect: (_, __) => '/patient',
      ),
      GoRoute(
        path: '/patient/profile',
        builder: (_, __) => const PatientProfileScreen(),
      ),
      GoRoute(
        path: '/patient/departments',
        builder: (_, __) => const DepartmentsScreen(),
      ),
      GoRoute(
        path: '/patient/departments/slots',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SlotsScreen(
            departmentId: extra['departmentId'] as String,
            departmentName: extra['departmentName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/patient/book',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookAppointmentScreen(slotData: extra);
        },
      ),
      GoRoute(
        path: '/patient/booking-confirmation',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingConfirmationScreen(
            appointmentId: extra['appointmentId'] as String,
            departmentName: extra['departmentName'] as String,
            appointmentDate: extra['appointmentDate'] as String,
            appointmentTime: extra['appointmentTime'] as String,
            status: extra['status'] as String? ?? 'Confirmed',
          );
        },
      ),
      GoRoute(
        path: '/patient/appointments',
        builder: (_, __) => const PatientAppointmentsScreen(),
      ),
      GoRoute(
        path: '/patient/appointments/:id',
        builder: (_, state) => AppointmentDetailScreen(
          appointmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/patient/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ── Staff ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/staff',
        redirect: (_, __) => '/account-pending',
      ),
      GoRoute(
        path: '/staff-home',
        redirect: (_, __) => '/staff',
      ),
      GoRoute(
        path: '/staff/appointments',
        builder: (_, __) => const StaffAppointmentsScreen(),
      ),
      GoRoute(
        path: '/staff/appointments/:id',
        builder: (_, state) => StaffAppointmentDetailScreen(
          appointmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/staff/schedules',
        builder: (_, __) => const ManageSlotsScreen(),
      ),
      GoRoute(
        path: '/staff/patients',
        builder: (_, __) => const StaffPatientsScreen(),
      ),
      GoRoute(
        path: '/staff/reports',
        builder: (_, __) => const ReportsScreen(),
      ),

      GoRoute(
        path: '/receptionist',
        builder: (_, __) => const ReceptionistDashboardScreen(),
      ),
      GoRoute(
        path: '/doctor',
        builder: (_, __) => const DoctorDashboardScreen(),
      ),
      GoRoute(
        path: '/scheduling',
        builder: (_, __) => const SchedulingOfficerDashboardScreen(),
      ),

      // ── Admin ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin-home',
        redirect: (_, __) => '/admin',
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/admin/users/create-staff',
        builder: (_, __) => const CreateStaffAccountScreen(),
      ),
      GoRoute(
        path: '/admin/departments',
        builder: (_, __) => const ManageDepartmentsScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (_, __) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/admin/audit',
        builder: (_, __) => const AuditLogsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}',
            style: const TextStyle(fontSize: 16)),
      ),
    ),
  );

  static String dashboardForRole(UserRole role) {
    if (role.isAdmin) return '/admin';
    if (role.isDoctor) return '/doctor';
    if (role.isReceptionist) return '/receptionist';
    if (role.isSchedulingOfficer) return '/scheduling';
    if (role.isPatient) return '/patient';
    return '/account-pending';
  }
}
