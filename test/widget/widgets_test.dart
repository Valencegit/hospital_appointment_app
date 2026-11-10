import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appointmentapp/core/enums/user_role.dart';
import 'package:appointmentapp/shared/widgets/app_logo.dart';
import 'package:appointmentapp/shared/widgets/custom_button.dart';
import 'package:appointmentapp/shared/widgets/custom_text_field.dart';
import 'package:appointmentapp/shared/widgets/role_badge.dart';

void main() {
  group('Shared Widgets Tests', () {
    testWidgets('CustomButton renders text and triggers callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Book Appointment',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Book Appointment'), findsOneWidget);
      await tester.tap(find.text('Book Appointment'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('CustomButton shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Save',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('RoleBadge displays appropriate title and icon for patient and doctor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RoleBadge(role: UserRole.patient),
                RoleBadge(role: UserRole.doctor),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Patient'), findsOneWidget);
      expect(find.text('Doctor / Specialist'), findsOneWidget);
    });

    testWidgets('CustomTextField renders label and hintText', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Medical Registration ID',
              hintText: 'Enter MRN',
            ),
          ),
        ),
      );

      expect(find.text('Medical Registration ID'), findsOneWidget);
      expect(find.text('Enter MRN'), findsOneWidget);
    });

    testWidgets('AppLogo renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(size: 80),
          ),
        ),
      );

      expect(find.byType(AppLogo), findsOneWidget);
    });
  });
}
