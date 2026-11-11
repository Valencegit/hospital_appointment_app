import 'package:flutter_test/flutter_test.dart';
import 'package:appointmentapp/core/enums/user_role.dart';
import 'package:appointmentapp/models/admin_model.dart';
import 'package:appointmentapp/models/patient_model.dart';
import 'package:appointmentapp/models/staff_model.dart';
import 'package:appointmentapp/models/user_model.dart';

void main() {
  group('User Models Unit Tests', () {
    test('UserModel serialization and role getters', () {
      final now = DateTime(2026, 10, 24, 10, 30);
      final user = UserModel(
        uid: 'user_123',
        email: 'sarah.jenkins@hospital.com',
        fullName: 'Sarah Jenkins',
        phoneNumber: '+15551234567',
        role: 'patient',
        createdAt: now,
      );

      expect(user.isPatient, isTrue);
      expect(user.isDoctor, isFalse);
      expect(user.isAdmin, isFalse);
      expect(user.firstName, 'Sarah');
      expect(user.lastName, 'Jenkins');
      expect(user.initials, 'SJ');

      final map = user.toMap();
      expect(map['uid'], 'user_123');
      expect(map['email'], 'sarah.jenkins@hospital.com');
      expect(map['role'], 'patient');

      final deserialized = UserModel.fromMap(map, documentId: 'user_123');
      expect(deserialized.uid, user.uid);
      expect(deserialized.email, user.email);
      expect(deserialized.fullName, user.fullName);
      expect(deserialized.role, user.role);
    });

    test('PatientModel serialization and helper getters', () {
      final now = DateTime(2026, 10, 24);
      final patient = PatientModel(
        uid: 'patient_456',
        firstName: 'Michael',
        lastName: 'Scott',
        email: 'michael@dunder.com',
        phoneNumber: '+15559876543',
        dateOfBirth: DateTime(1984, 3, 15),
        gender: 'Male',
        bloodGroup: 'A+',
        emergencyContactName: 'Dwight Schrute',
        emergencyContactPhone: '+15551112222',
        createdAt: now,
      );

      expect(patient.patientId, 'patient_456');
      expect(patient.fullName, 'Michael Scott');
      expect(patient.bloodGroup, 'A+');
      expect(patient.emergencyContact, 'Dwight Schrute (+15551112222)');

      final map = patient.toMap();
      final deserialized = PatientModel.fromMap(map, documentId: 'patient_456');
      expect(deserialized.uid, 'patient_456');
      expect(deserialized.bloodGroup, 'A+');
      expect(deserialized.dateOfBirth, DateTime(1984, 3, 15));
      expect(deserialized.gender, 'Male');
    });

    test('StaffModel serialization and specialization attributes', () {
      final now = DateTime(2026, 10, 24);
      final doctor = StaffModel(
        uid: 'doc_789',
        firstName: 'Daniel',
        lastName: 'Mitchell',
        email: 'dr.daniel@hospital.com',
        phoneNumber: '+15553334444',
        employeeId: 'HOSP-2026-19',
        staffRole: 'doctor',
        departmentName: 'Cardiology',
        specialization: 'Consultant Cardiologist',
        licenseNumber: 'CARD-2026-99',
        consultationFee: 120.0,
        createdAt: now,
      );

      expect(doctor.role, UserRole.doctor);
      expect(doctor.departmentName, 'Cardiology');
      expect(doctor.specialization, 'Consultant Cardiologist');
      expect(doctor.consultationFee, 120.0);
      expect(doctor.employeeId, 'HOSP-2026-19');

      final map = doctor.toMap();
      final deserialized = StaffModel.fromMap(map, documentId: 'doc_789');
      expect(deserialized.licenseNumber, 'CARD-2026-99');
      expect(deserialized.consultationFee, 120.0);
      expect(deserialized.employeeId, 'HOSP-2026-19');
    });

    test('AdminModel serialization and permissions verification', () {
      final now = DateTime(2026, 10, 24);
      final admin = AdminModel(
        uid: 'admin_001',
        fullName: 'Karen Wood',
        email: 'admin.karen@hospital.com',
        department: 'Clinical Operations',
        permissions: const ['manage_users', 'manage_staff', 'manage_slots'],
        createdAt: now,
      );

      expect(admin.adminId, 'admin_001');
      expect(admin.permissions, contains('manage_users'));
      expect(admin.permissions.length, 3);

      final map = admin.toMap();
      final deserialized = AdminModel.fromMap(map, documentId: 'admin_001');
      expect(deserialized.permissions, contains('manage_slots'));
      expect(deserialized.department, 'Clinical Operations');
    });
  });
}
