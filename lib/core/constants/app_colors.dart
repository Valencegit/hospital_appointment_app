import 'package:flutter/material.dart';

/// Modern royal blue and crisp clinical palette for Metro Health Hospital.
class AppColors {
  AppColors._();

  // Primary Clinical Palette (Metro Health Royal Blue)
  static const Color primary = Color(0xFF0B63E5);
  static const Color primaryDark = Color(0xFF004EC4);
  static const Color primaryLight = Color(0xFFEBF3FE);
  static const Color primaryContainer = Color(0xFFDBEAFE);

  // Secondary & Accents
  static const Color secondary = Color(0xFF0284C7);
  static const Color secondaryLight = Color(0xFFE0F2FE);
  static const Color secondaryDark = Color(0xFF0369A1);
  static const Color accent = Color(0xFF2563EB);

  // Neutral & Surfaces (Light)
  static const Color background = Color(0xFFF4F7FB);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFDCE4EE);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1A2B49);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Feedback & State Colors
  static const Color success = Color(0xFF0EA568);
  static const Color successLight = Color(0xFFE8F8F0);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF6E7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0B63E5);
  static const Color infoLight = Color(0xFFEBF3FE);

  // Role Badges & Indicators
  static const Color rolePatient = Color(0xFF0B63E5);
  static const Color rolePatientBg = Color(0xFFEBF3FE);

  static const Color roleDoctor = Color(0xFF2563EB);
  static const Color roleDoctorBg = Color(0xFFDBEAFE);

  static const Color roleStaff = Color(0xFF0284C7);
  static const Color roleStaffBg = Color(0xFFE0F2FE);

  static const Color roleReceptionist = Color(0xFFD97706);
  static const Color roleReceptionistBg = Color(0xFFFEF6E7);

  static const Color roleAdmin = Color(0xFF7C3AED);
  static const Color roleAdminBg = Color(0xFFEDE9FE);

  // Status Badge Colors (for appointment workflows)
  static const Color statusPending = Color(0xFFFEF6E7);
  static const Color statusPendingText = Color(0xFFD97706);
  static const Color statusConfirmed = Color(0xFFE8F8F0);
  static const Color statusConfirmedText = Color(0xFF0EA568);
  static const Color statusCancelled = Color(0xFFFEE2E2);
  static const Color statusCancelledText = Color(0xFFDC2626);
  static const Color statusCompleted = Color(0xFFEBF3FE);
  static const Color statusCompletedText = Color(0xFF0B63E5);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF475569);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}
