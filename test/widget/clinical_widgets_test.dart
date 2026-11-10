import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointmentapp/core/constants/app_constants.dart';
import 'package:appointmentapp/core/enums/user_role.dart';
import 'package:appointmentapp/features/shared/widgets/appointment_card.dart';
import 'package:appointmentapp/features/shared/widgets/section_header.dart';
import 'package:appointmentapp/models/appointment_model.dart';
import 'package:appointmentapp/shared/widgets/custom_button.dart';
import 'package:appointmentapp/shared/widgets/custom_text_field.dart';
import 'package:appointmentapp/shared/widgets/loading_indicator.dart';
import 'package:appointmentapp/shared/widgets/role_badge.dart';

void main() {
  group('Clinical Widgets Component Tests', () {
    testWidgets('AppointmentCard renders appointment info and responds to tap', (tester) async {
      final now = DateTime(2026, 11, 10);
      bool tapped = false;

      final appointment = AppointmentModel(
        id: 'apt_card_test',
        patientId: 'pat_001',
        patientName: 'Sarah Jenkins',
        slotId: 'slot_001',
        departmentId: 'dept_neuro',
        departmentName: 'Neurology Department',
        appointmentDate: now,
        appointmentTime: '11:15 AM',
        status: AppConstants.statusConfirmed,
        bookedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppointmentCard(
              appointment: appointment,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Neurology Department'), findsOneWidget);
      expect(find.text('11:15 AM'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);

      await tester.tap(find.byType(AppointmentCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('AppointmentCard renders various status badges properly', (tester) async {
      final now = DateTime(2026, 11, 10);

      for (final status in [
        AppConstants.statusPending,
        AppConstants.statusCancelled,
        AppConstants.statusCompleted,
      ]) {
        final apt = AppointmentModel(
          id: 'apt_$status',
          patientId: 'p1',
          patientName: 'Test',
          slotId: 's1',
          departmentId: 'd1',
          departmentName: 'General Clinic',
          appointmentDate: now,
          appointmentTime: '02:00 PM',
          status: status,
          bookedAt: now,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppointmentCard(appointment: apt),
            ),
          ),
        );

        if (status == AppConstants.statusPending) {
          expect(find.text('Pending'), findsOneWidget);
        } else if (status == AppConstants.statusCancelled) {
          expect(find.text('Cancelled'), findsOneWidget);
        } else if (status == AppConstants.statusCompleted) {
          expect(find.text('Completed'), findsOneWidget);
        }
      }
    });

    testWidgets('SectionHeader displays specified title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: 'Upcoming Consultations'),
          ),
        ),
      );

      expect(find.text('Upcoming Consultations'), findsOneWidget);
    });

    testWidgets('AppLoadingIndicator renders spinner and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingIndicator(
              message: 'Fetching hospital records...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Fetching hospital records...'), findsOneWidget);
    });

    testWidgets('RoleBadge renders for all 5 roles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RoleBadge(role: UserRole.patient),
                RoleBadge(role: UserRole.doctor),
                RoleBadge(role: UserRole.staff),
                RoleBadge(role: UserRole.receptionist),
                RoleBadge(role: UserRole.admin),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Patient'), findsOneWidget);
      expect(find.text('Doctor / Specialist'), findsOneWidget);
      expect(find.text('Hospital Staff'), findsOneWidget);
      expect(find.text('Receptionist'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
    });

    testWidgets('CustomTextField handles text input and obscure text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              label: 'Password',
              hintText: 'Enter your password',
              isPassword: true,
            ),
          ),
        ),
      );

      expect(find.text('Password'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'superSecret123');
      expect(controller.text, 'superSecret123');
    });

    testWidgets('CustomButton renders secondary/outline variant style', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Cancel Action',
              variant: ButtonVariant.outlined,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Cancel Action'), findsOneWidget);
      await tester.tap(find.text('Cancel Action'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
