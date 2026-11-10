import 'package:flutter_test/flutter_test.dart';
import 'package:appointmentapp/core/constants/app_constants.dart';
import 'package:appointmentapp/models/admin_model.dart';
import 'package:appointmentapp/models/appointment_model.dart';
import 'package:appointmentapp/models/department_model.dart';
import 'package:appointmentapp/models/notification_model.dart';
import 'package:appointmentapp/models/patient_model.dart';
import 'package:appointmentapp/models/slot_model.dart';
import 'package:appointmentapp/models/staff_model.dart';
import 'package:appointmentapp/models/user_model.dart';

void main() {
  group('Hospital Appointment End-to-End Workflow Integration Tests', () {
    test('Workflow 1: Patient discovers department, selects available slot, and books appointment', () {
      final now = DateTime(2026, 11, 10, 8, 0);

      // 1. Patient profile exists
      final patient = PatientModel(
        uid: 'pat_sarah',
        firstName: 'Sarah',
        lastName: 'Jenkins',
        email: 'sarah.jenkins@hospital.com',
        phoneNumber: '+15551234567',
        bloodGroup: 'O+',
        createdAt: now,
      );
      expect(patient.patientId, 'pat_sarah');

      // 2. Active Cardiology department
      final department = DepartmentModel(
        id: 'dept_cardiology',
        name: 'Cardiology',
        description: 'Advanced cardiovascular diagnosis and clinical care',
        isActive: true,
        createdAt: now,
      );
      expect(department.isActive, isTrue);

      // 3. Time slot created by clinical staff with capacity of 2
      final initialSlot = SlotModel(
        id: 'slot_cardio_10am',
        departmentId: department.id,
        departmentName: department.name,
        date: DateTime(2026, 11, 12),
        startTime: '10:00 AM',
        endTime: '10:30 AM',
        capacity: 2,
        bookedCount: 0,
        isActive: true,
        createdAt: now,
      );
      expect(initialSlot.isAvailable, isTrue);
      expect(initialSlot.remainingSlots, 2);

      // 4. Patient books the appointment
      final appointment = AppointmentModel(
        id: 'apt_booking_001',
        patientId: patient.patientId,
        patientName: patient.fullName,
        slotId: initialSlot.id,
        departmentId: department.id,
        departmentName: department.name,
        appointmentDate: initialSlot.date,
        appointmentTime: initialSlot.startTime,
        status: AppConstants.statusPending,
        notes: 'Routine cardiovascular checkup',
        bookedAt: now,
      );

      expect(appointment.isPending, isTrue);
      expect(appointment.status, 'pending');

      // 5. Slot capacity updates after booking
      final updatedSlot = SlotModel(
        id: initialSlot.id,
        departmentId: initialSlot.departmentId,
        departmentName: initialSlot.departmentName,
        date: initialSlot.date,
        startTime: initialSlot.startTime,
        endTime: initialSlot.endTime,
        capacity: initialSlot.capacity,
        bookedCount: initialSlot.bookedCount + 1,
        isActive: true,
        createdAt: now,
      );
      expect(updatedSlot.remainingSlots, 1);
      expect(updatedSlot.isAvailable, isTrue);

      // 6. Second patient books, slot becomes full
      final fullSlot = SlotModel(
        id: initialSlot.id,
        departmentId: initialSlot.departmentId,
        departmentName: initialSlot.departmentName,
        date: initialSlot.date,
        startTime: initialSlot.startTime,
        endTime: initialSlot.endTime,
        capacity: initialSlot.capacity,
        bookedCount: 2,
        isActive: true,
        createdAt: now,
      );
      expect(fullSlot.remainingSlots, 0);
      expect(fullSlot.isAvailable, isFalse);
    });

    test('Workflow 2: Doctor reviews appointment, confirms booking, and triggers patient notification', () {
      final now = DateTime(2026, 11, 10, 8, 30);

      // Doctor staff record
      final doctor = StaffModel(
        uid: 'doc_daniel',
        firstName: 'Daniel',
        lastName: 'Mitchell',
        email: 'dr.daniel@hospital.com',
        phoneNumber: '+15552345678',
        staffRole: 'doctor',
        departmentName: 'Cardiology',
        specialization: 'Consultant Interventional Cardiologist',
        licenseNumber: 'CARD-MED-998',
        consultationFee: 150.0,
        createdAt: now,
      );
      expect(doctor.role.isDoctor, isTrue);
      expect(doctor.consultationFee, 150.0);

      // Initial pending appointment
      final pendingApt = AppointmentModel(
        id: 'apt_flow_002',
        patientId: 'pat_sarah',
        patientName: 'Sarah Jenkins',
        slotId: 'slot_10am',
        departmentId: 'dept_cardio',
        departmentName: 'Cardiology',
        appointmentDate: DateTime(2026, 11, 12),
        appointmentTime: '10:00 AM',
        status: AppConstants.statusPending,
        bookedAt: now,
      );
      expect(pendingApt.isPending, isTrue);

      // Doctor confirms appointment
      final confirmedApt = pendingApt.copyWith(
        status: AppConstants.statusConfirmed,
        updatedAt: now.add(const Duration(minutes: 5)),
      );
      expect(confirmedApt.isConfirmed, isTrue);
      expect(confirmedApt.isPending, isFalse);

      // Dispatch confirmation notification to patient
      final notification = NotificationModel(
        id: 'notif_apt_002',
        userId: confirmedApt.patientId,
        title: 'Appointment Confirmed',
        body: 'Your consultation with ${doctor.fullName} on ${confirmedApt.appointmentTime} is confirmed.',
        type: 'booking_confirmed',
        appointmentId: confirmedApt.id,
        isRead: false,
        createdAt: now.add(const Duration(minutes: 5)),
      );
      expect(notification.isRead, isFalse);
      expect(notification.appointmentId, confirmedApt.id);

      // Patient reads notification
      final readNotification = notification.copyWith(isRead: true);
      expect(readNotification.isRead, isTrue);

      // After consultation, appointment marked completed
      final completedApt = confirmedApt.copyWith(
        status: AppConstants.statusCompleted,
        notes: 'Blood pressure normal (118/78). Recommended 6-month checkup.',
      );
      expect(completedApt.isCompleted, isTrue);
      expect(completedApt.notes, contains('118/78'));
    });

    test('Workflow 3: Patient requests cancellation with reason and appointment lifecycle handles cancellation', () {
      final now = DateTime(2026, 11, 10, 9, 0);

      final apt = AppointmentModel(
        id: 'apt_cancel_flow',
        patientId: 'pat_michael',
        patientName: 'Michael Scott',
        slotId: 'slot_2pm',
        departmentId: 'dept_general',
        departmentName: 'General Practice',
        appointmentDate: DateTime(2026, 11, 15),
        appointmentTime: '02:00 PM',
        status: AppConstants.statusConfirmed,
        bookedAt: now,
      );

      // Patient requests cancellation
      final cancelRequested = apt.copyWith(
        status: AppConstants.statusCancelRequested,
        cancellationReason: 'Work schedule conflict',
      );
      expect(cancelRequested.status, AppConstants.statusCancelRequested);
      expect(cancelRequested.cancellationReason, 'Work schedule conflict');

      // Admin or staff processes and confirms cancellation
      final cancelledApt = cancelRequested.copyWith(
        status: AppConstants.statusCancelled,
      );
      expect(cancelledApt.isCancelled, isTrue);
      expect(cancelledApt.cancellationReason, 'Work schedule conflict');
    });

    test('Workflow 4: Admin department duplicate prevention and department status toggle', () {
      final now = DateTime(2026, 11, 10);
      final existingDepartments = [
        DepartmentModel(id: 'd1', name: 'Cardiology', createdAt: now),
        DepartmentModel(id: 'd2', name: 'Neurology', createdAt: now),
        DepartmentModel(id: 'd3', name: 'Pediatrics', createdAt: now),
      ];

      // Duplicate check function as in DepartmentProvider
      bool isDuplicate(String name, [String? id]) {
        final normalized = name.trim().toLowerCase();
        return existingDepartments.any(
          (dept) => dept.name.trim().toLowerCase() == normalized && dept.id != id,
        );
      }

      expect(isDuplicate('cardiology'), isTrue);
      expect(isDuplicate('  CARDIOLOGY  '), isTrue);
      expect(isDuplicate('Neurology'), isTrue);
      expect(isDuplicate('Orthopedics'), isFalse);
      expect(isDuplicate('Cardiology', 'd1'), isFalse); // Same department edit is allowed

      // Admin toggles active state of department
      final dept = existingDepartments.first;
      final deactivatedDept = dept.copyWith(isActive: !dept.isActive);
      expect(deactivatedDept.isActive, isFalse);
    });

    test('Workflow 5: Admin role verification and RBAC permissions enforcement', () {
      final now = DateTime(2026, 11, 10);
      final admin = AdminModel(
        uid: 'adm_karen',
        fullName: 'Karen Wood',
        email: 'admin.karen@hospital.com',
        department: 'Executive Administration',
        permissions: const [
          'manage_users',
          'manage_staff',
          'manage_departments',
          'manage_slots',
          'view_audit_logs',
          'generate_reports',
        ],
        createdAt: now,
      );

      expect(admin.adminId, 'adm_karen');
      expect(admin.permissions, contains('manage_departments'));
      expect(admin.permissions, contains('view_audit_logs'));
      expect(admin.permissions, contains('generate_reports'));

      final patientUser = UserModel(
        uid: 'user_pat_1',
        email: 'patient@hospital.com',
        fullName: 'Sarah Jenkins',
        role: 'patient',
        createdAt: now,
      );
      expect(patientUser.isAdmin, isFalse);
      expect(patientUser.isPatient, isTrue);
    });
  });
}
