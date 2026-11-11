import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:appointmentapp/core/constants/app_colors.dart';
import 'package:appointmentapp/core/constants/app_constants.dart';
import 'package:appointmentapp/core/enums/user_role.dart';
import 'package:appointmentapp/core/theme/app_theme.dart';
import 'package:appointmentapp/core/utils/date_formatter.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Core Utilities & Constants Tests', () {
    test('DateFormatter formats timestamps correctly', () {
      final testDate = DateTime(2026, 11, 10, 14, 30);

      expect(DateFormatter.formatDate(testDate), '10 Nov 2026');
      expect(DateFormatter.formatDateTime(testDate), '10 Nov 2026, 02:30 PM');
      expect(DateFormatter.formatTime(testDate), '02:30 PM');
      expect(DateFormatter.formatShortDate(testDate), '10/11/2026');
      expect(DateFormatter.formatDayMonth(testDate), 'Tue, 10 Nov');
    });

    test('DateFormatter timeAgo handles various durations', () {
      final now = DateTime.now();
      expect(DateFormatter.timeAgo(now.subtract(const Duration(seconds: 30))),
          'Just now');
      expect(DateFormatter.timeAgo(now.subtract(const Duration(minutes: 5))),
          '5m ago');
      expect(DateFormatter.timeAgo(now.subtract(const Duration(hours: 3))),
          '3h ago');
      expect(DateFormatter.timeAgo(now.subtract(const Duration(days: 4))),
          '4d ago');
      final pastDate = now.subtract(const Duration(days: 10));
      expect(
          DateFormatter.timeAgo(pastDate), DateFormatter.formatDate(pastDate));
    });

    test('UserRole conversions, role queries and display attributes', () {
      expect(UserRole.fromString('patient'), UserRole.patient);
      expect(UserRole.fromString('doctor'), UserRole.doctor);
      expect(UserRole.fromString('staff'), UserRole.staff);
      expect(UserRole.fromString('healthcare_professional'), UserRole.staff);
      expect(UserRole.fromString('schedulingOfficer'), UserRole.schedulingOfficer);
      expect(UserRole.fromString('Scheduling Officer'), UserRole.schedulingOfficer);
      expect(UserRole.fromString('pending'), UserRole.pending);
      expect(UserRole.fromString('receptionist'), UserRole.receptionist);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('administrator'), UserRole.admin);
      expect(UserRole.fromString('unknown_role'), UserRole.pending);
      expect(UserRole.fromString(null), UserRole.pending);

      expect(UserRole.patient.toValue(), 'patient');
      expect(UserRole.doctor.toValue(), 'doctor');
      expect(UserRole.staff.toValue(), 'staff');
      expect(UserRole.schedulingOfficer.toValue(), 'scheduling_officer');
      expect(UserRole.receptionist.toValue(), 'receptionist');
      expect(UserRole.admin.toValue(), 'admin');

      expect(UserRole.patient.displayName, 'Patient');
      expect(UserRole.doctor.displayName, 'Doctor');
      expect(UserRole.staff.displayName, 'Staff (Legacy)');
      expect(UserRole.receptionist.displayName, 'Receptionist');
      expect(UserRole.admin.displayName, 'Administrator');

      expect(UserRole.patient.isPatient, isTrue);
      expect(UserRole.patient.isStaff, isFalse);
      expect(UserRole.doctor.isDoctor, isTrue);
      expect(UserRole.doctor.isStaff, isTrue);
      expect(UserRole.receptionist.isStaff, isTrue);
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.admin.isDoctor, isFalse);
    });

    test('AppConstants values are correct', () {
      expect(AppConstants.appName, 'MediCare Hospital');
      expect(AppConstants.statusPending, 'pending');
      expect(AppConstants.statusConfirmed, 'confirmed');
      expect(AppConstants.statusCancelled, 'cancelled');
      expect(AppConstants.statusCompleted, 'completed');
      expect(AppConstants.statusRescheduled, 'rescheduled');
      expect(AppConstants.statusCancelRequested, 'cancel_requested');
      expect(AppConstants.statusRescheduleRequested, 'reschedule_requested');
      expect(AppConstants.colAppointments, 'appointments');
      expect(AppConstants.colDepartments, 'departments');
      expect(AppConstants.colAppointmentSlots, 'appointment_slots');
      expect(AppConstants.colNotifications, 'notifications');
      expect(AppConstants.minPasswordLength, 6);
      expect(AppConstants.minNameLength, 2);
    });

    test('AppColors palette definitions', () {
      expect(AppColors.primary, const Color(0xFF0B63E5));
      expect(AppColors.success, const Color(0xFF0EA568));
      expect(AppColors.error, const Color(0xFFEF4444));
      expect(AppColors.warning, const Color(0xFFD97706));
      expect(AppColors.statusPendingText, const Color(0xFFD97706));
      expect(AppColors.statusConfirmedText, const Color(0xFF0EA568));
    });

    testWidgets('AppTheme generates light and dark themes properly',
        (tester) async {
      final light = AppTheme.lightTheme;
      expect(light.brightness, Brightness.light);
      expect(light.useMaterial3, isTrue);
      expect(light.colorScheme.primary, AppColors.primary);

      final dark = AppTheme.darkTheme;
      expect(dark.brightness, Brightness.dark);
      expect(dark.useMaterial3, isTrue);
    });
  });
}
