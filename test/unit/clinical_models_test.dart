import 'package:flutter_test/flutter_test.dart';
import 'package:appointmentapp/core/constants/app_constants.dart';
import 'package:appointmentapp/models/appointment_model.dart';
import 'package:appointmentapp/models/department_model.dart';
import 'package:appointmentapp/models/notification_model.dart';
import 'package:appointmentapp/models/slot_model.dart';

void main() {
  group('Clinical Models Tests', () {
    test('AppointmentModel status getters and copyWith', () {
      final now = DateTime(2026, 11, 10, 9, 30);
      final apt = AppointmentModel(
        id: 'apt_001',
        patientId: 'pat_001',
        patientName: 'Sarah Jenkins',
        slotId: 'slot_001',
        departmentId: 'dept_cardio',
        departmentName: 'Cardiology',
        appointmentDate: now,
        appointmentTime: '09:30 AM',
        status: AppConstants.statusPending,
        bookedAt: now,
      );

      expect(apt.isPending, isTrue);
      expect(apt.isConfirmed, isFalse);
      expect(apt.isCancelled, isFalse);
      expect(apt.isCompleted, isFalse);

      final confirmedApt = apt.copyWith(status: AppConstants.statusConfirmed);
      expect(confirmedApt.isPending, isFalse);
      expect(confirmedApt.isConfirmed, isTrue);

      final cancelledApt = apt.copyWith(
        status: AppConstants.statusCancelled,
        cancellationReason: 'Emergency rescheduling',
      );
      expect(cancelledApt.isCancelled, isTrue);
      expect(cancelledApt.cancellationReason, 'Emergency rescheduling');

      final completedApt = apt.copyWith(
        status: AppConstants.statusCompleted,
        notes: 'Follow-up in 2 weeks',
      );
      expect(completedApt.isCompleted, isTrue);
      expect(completedApt.notes, 'Follow-up in 2 weeks');
    });

    test('SlotModel availability and capacity calculations', () {
      final now = DateTime(2026, 11, 10);
      final slot = SlotModel(
        id: 'slot_101',
        departmentId: 'dept_cardio',
        departmentName: 'Cardiology',
        date: now,
        startTime: '10:00 AM',
        endTime: '10:30 AM',
        capacity: 3,
        bookedCount: 1,
        isActive: true,
        createdAt: now,
      );

      expect(slot.isAvailable, isTrue);
      expect(slot.remainingSlots, 2);

      final fullSlot = SlotModel(
        id: 'slot_102',
        departmentId: 'dept_cardio',
        departmentName: 'Cardiology',
        date: now,
        startTime: '10:30 AM',
        endTime: '11:00 AM',
        capacity: 3,
        bookedCount: 3,
        isActive: true,
        createdAt: now,
      );
      expect(fullSlot.isAvailable, isFalse);
      expect(fullSlot.remainingSlots, 0);

      final inactiveSlot = SlotModel(
        id: 'slot_103',
        departmentId: 'dept_cardio',
        departmentName: 'Cardiology',
        date: now,
        startTime: '11:00 AM',
        endTime: '11:30 AM',
        capacity: 5,
        bookedCount: 1,
        isActive: false,
        createdAt: now,
      );
      expect(inactiveSlot.isAvailable, isFalse);
    });

    test('DepartmentModel creation and copyWith modification', () {
      final now = DateTime(2026, 11, 10);
      final dept = DepartmentModel(
        id: 'dept_pediatrics',
        name: 'Pediatrics',
        description: 'Comprehensive child healthcare',
        iconName: 'heart-pulse',
        isActive: true,
        createdAt: now,
      );

      expect(dept.id, 'dept_pediatrics');
      expect(dept.name, 'Pediatrics');
      expect(dept.isActive, isTrue);

      final updatedDept = dept.copyWith(
        name: 'Pediatrics & Neonatal',
        isActive: false,
      );
      expect(updatedDept.name, 'Pediatrics & Neonatal');
      expect(updatedDept.isActive, isFalse);
      expect(updatedDept.id, 'dept_pediatrics');
    });

    test('NotificationModel read state and copyWith', () {
      final now = DateTime(2026, 11, 10);
      final notification = NotificationModel(
        id: 'notif_001',
        userId: 'user_123',
        title: 'Appointment Confirmed',
        body: 'Your appointment for Cardiology has been confirmed.',
        type: 'booking_confirmed',
        appointmentId: 'apt_001',
        isRead: false,
        createdAt: now,
      );

      expect(notification.isRead, isFalse);
      expect(notification.type, 'booking_confirmed');

      final readNotification = notification.copyWith(isRead: true);
      expect(readNotification.isRead, isTrue);
      expect(readNotification.id, 'notif_001');
      expect(readNotification.body, notification.body);
    });
  });
}
