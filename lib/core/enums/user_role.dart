import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Enumeration of user roles supported in the hospital system.
enum UserRole {
  patient,
  staff,
  doctor,
  receptionist,
  admin;

  /// Convert string from Firestore or backend to UserRole enum.
  static UserRole fromString(String? role) {
    switch (role?.toLowerCase().trim()) {
      case 'patient':
        return UserRole.patient;
      case 'staff':
      case 'healthcare_professional':
        return UserRole.staff;
      case 'doctor':
        return UserRole.doctor;
      case 'receptionist':
        return UserRole.receptionist;
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }

  /// String value saved in Firestore documents.
  String toValue() {
    switch (this) {
      case UserRole.patient:
        return 'patient';
      case UserRole.staff:
        return 'staff';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.receptionist:
        return 'receptionist';
      case UserRole.admin:
        return 'admin';
    }
  }

  /// User-friendly display label.
  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.staff:
        return 'Hospital Staff';
      case UserRole.doctor:
        return 'Doctor / Specialist';
      case UserRole.receptionist:
        return 'Receptionist';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  /// Associated icon for UI presentation.
  IconData get icon {
    switch (this) {
      case UserRole.patient:
        return BootstrapIcons.person;
      case UserRole.staff:
        return BootstrapIcons.person_badge;
      case UserRole.doctor:
        return BootstrapIcons.bag_plus;
      case UserRole.receptionist:
        return BootstrapIcons.headset;
      case UserRole.admin:
        return BootstrapIcons.shield_lock;
    }
  }

  bool get isPatient => this == UserRole.patient;
  bool get isDoctor => this == UserRole.doctor;
  bool get isStaff =>
      this == UserRole.staff ||
      this == UserRole.doctor ||
      this == UserRole.receptionist;
  bool get isAdmin => this == UserRole.admin;
}
