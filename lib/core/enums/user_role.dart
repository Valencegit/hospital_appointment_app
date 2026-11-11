import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Enumeration of user roles supported in the hospital system.
///
/// Role strings are stored in Firestore and set as Firebase Auth custom claims
/// by Cloud Functions. The Flutter app reads the role from the token claim
/// (via RoleService) — never from a user-supplied value.
enum UserRole {
  patient,
  receptionist,
  doctor,
  schedulingOfficer,
  admin,

  /// Transitional value for accounts awaiting role assignment by an admin.
  pending,

  /// Legacy role — kept to parse old Firestore documents.
  /// Admins must migrate these accounts to a specific role.
  staff;

  // ── Parsing ──────────────────────────────────────────────────────────────

  static UserRole fromString(String? role) {
    final normalized = _normalizeRole(role);

    switch (normalized) {
      case 'patient':
        return UserRole.patient;
      case 'receptionist':
        return UserRole.receptionist;
      case 'doctor':
        return UserRole.doctor;
      case 'scheduling_officer':
        return UserRole.schedulingOfficer;
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'staff':
      case 'healthcare_professional':
        return UserRole.staff;
      case 'pending':
        return UserRole.pending;
      default:
        return UserRole.pending;
    }
  }

  static String _normalizeRole(String? role) {
    if (role == null) return '';

    var normalized = role.trim();
    normalized = normalized.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)}_${match.group(2)}',
    );
    normalized = normalized.replaceAll(RegExp(r'[\s\-]+'), '_');
    normalized = normalized.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return normalized.toLowerCase();
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  /// String value stored in Firestore and set as a Firebase Auth custom claim.
  String toValue() {
    switch (this) {
      case UserRole.patient:
        return 'patient';
      case UserRole.receptionist:
        return 'receptionist';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.schedulingOfficer:
        return 'scheduling_officer';
      case UserRole.admin:
        return 'admin';
      case UserRole.staff:
        return 'staff';
      case UserRole.pending:
        return 'pending';
    }
  }

  // ── Display ───────────────────────────────────────────────────────────────

  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.receptionist:
        return 'Receptionist';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.schedulingOfficer:
        return 'Scheduling Officer';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.staff:
        return 'Staff (Legacy)';
      case UserRole.pending:
        return 'Pending';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.patient:
        return BootstrapIcons.person;
      case UserRole.receptionist:
        return BootstrapIcons.headset;
      case UserRole.doctor:
        return BootstrapIcons.bag_plus;
      case UserRole.schedulingOfficer:
        return BootstrapIcons.calendar_week;
      case UserRole.admin:
        return BootstrapIcons.shield_lock;
      case UserRole.staff:
        return BootstrapIcons.person_badge;
      case UserRole.pending:
        return BootstrapIcons.hourglass;
    }
  }

  // ── Role predicates ───────────────────────────────────────────────────────

  bool get isPatient => this == UserRole.patient;
  bool get isReceptionist => this == UserRole.receptionist;
  bool get isDoctor => this == UserRole.doctor;
  bool get isSchedulingOfficer => this == UserRole.schedulingOfficer;
  bool get isAdmin => this == UserRole.admin;
  bool get isPending => this == UserRole.pending;

  /// True for all clinical / operational staff roles.
  bool get isStaff =>
      this == UserRole.staff ||
      this == UserRole.doctor ||
      this == UserRole.receptionist ||
      this == UserRole.schedulingOfficer;
}
