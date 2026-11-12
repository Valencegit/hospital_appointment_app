import 'package:flutter/material.dart';

/// MediCare application palette used by the app theme and UI components.
class AppColors {
  AppColors._();

  // ── Primary brand palette ─────────────────────────────────────────────────
  /// Main blue used for primary buttons, links, and critical actions.
  static const Color primary = Color(0xFF0B63E5);

  /// Dark blue for headings, navigation emphasis, and elevated surfaces.
  static const Color primaryDark = Color(0xFF0A4DB1);

  /// Light blue background used for selected cards and subtle highlights.
  static const Color primaryLight = Color(0xFFE5F0FF);

  /// Medium blue container color.
  static const Color primaryContainer = Color(0xFFBFD9FF);

  // ── Secondary & Accents ───────────────────────────────────────────────────
  static const Color secondary = Color(0xFF00B4A8);
  static const Color secondaryLight = Color(0xFFE0FAF8);
  static const Color secondaryDark = Color(0xFF005F5A);
  static const Color accent = Color(0xFF00CFC0);

  // ── Neutral Surfaces (Light) ──────────────────────────────────────────────
  static const Color background = Color(0xFFF0FAFA);
  static const Color backgroundLight = Color(0xFFF8FFFE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFECF9F8);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFCCEEEB);
  static const Color border = Color(0xFFB2DED9);

  // ── Typography Colors ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textMuted = Color(0xFF90A4AE);
  static const Color textHint = Color(0xFF90A4AE);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Feedback & State Colors ───────────────────────────────────────────────
  static const Color success = Color(0xFF0EA568);
  static const Color successLight = Color(0xFFE0F2F1);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0097A7);
  static const Color infoLight = Color(0xFFE0F7FA);

  // ── Role Badges & Indicators ──────────────────────────────────────────────
  static const Color rolePatient = Color(0xFF008F87);
  static const Color rolePatientBg = Color(0xFFDDF7F4);

  static const Color roleDoctor = Color(0xFF006D68);
  static const Color roleDoctorBg = Color(0xFFB2EDE9);

  static const Color roleStaff = Color(0xFF00B4A8);
  static const Color roleStaffBg = Color(0xFFE0FAF8);

  static const Color roleReceptionist = Color(0xFFFF8F00);
  static const Color roleReceptionistBg = Color(0xFFFFF8E1);

  static const Color roleAdmin = Color(0xFF7C3AED);
  static const Color roleAdminBg = Color(0xFFEDE9FE);

  // ── Status Badge Colors ───────────────────────────────────────────────────
  static const Color statusPending = Color(0xFFFFF8E1);
  static const Color statusPendingText = Color(0xFFD97706);
  static const Color statusConfirmed = Color(0xFFE0F2F1);
  static const Color statusConfirmedText = Color(0xFF0EA568);
  static const Color statusCancelled = Color(0xFFFFEBEE);
  static const Color statusCancelledText = Color(0xFFEF4444);
  static const Color statusCompleted = Color(0xFFDDF7F4);
  static const Color statusCompletedText = Color(0xFF0B63E5);

  // ── Dark Theme Palette ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1F1E);
  static const Color darkSurface = Color(0xFF132928);
  static const Color darkSurfaceVariant = Color(0xFF1E3D3B);
  static const Color darkBorder = Color(0xFF2E5452);
  static const Color darkTextPrimary = Color(0xFFE0F4F3);
  static const Color darkTextSecondary = Color(0xFF80CBC4);
}
