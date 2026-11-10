import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Screen 8: Booking Confirmation — shown only after Firebase confirms
/// the appointment was successfully persisted.
class BookingConfirmationScreen extends StatelessWidget {
  final String appointmentId;
  final String departmentName;
  final String appointmentDate;
  final String appointmentTime;
  final String status;

  const BookingConfirmationScreen({
    super.key,
    required this.appointmentId,
    required this.departmentName,
    required this.appointmentDate,
    required this.appointmentTime,
    this.status = 'Confirmed',
  });

  @override
  Widget build(BuildContext context) {
    final ref = appointmentId.length >= 6
        ? appointmentId.substring(0, 6).toUpperCase()
        : appointmentId.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // ── Success Icon ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    BootstrapIcons.check_lg,
                    size: 52,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Heading ───────────────────────────────────────────────────
              const Text(
                'Appointment\nSuccessfully Booked',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your appointment has been confirmed.\nWe will send you a reminder before your visit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 36),

              // ── Appointment Details Card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2EBF7), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ConfirmRow(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Reference',
                      value: '#$ref',
                      valueColor: AppColors.primary,
                      valueBold: true,
                    ),
                    const Divider(height: 22, color: Color(0xFFF1F5F9)),
                    _ConfirmRow(
                      icon: BootstrapIcons.hospital,
                      label: 'Department',
                      value: departmentName,
                    ),
                    const Divider(height: 22, color: Color(0xFFF1F5F9)),
                    _ConfirmRow(
                      icon: BootstrapIcons.calendar_date,
                      label: 'Date',
                      value: appointmentDate,
                    ),
                    const Divider(height: 22, color: Color(0xFFF1F5F9)),
                    _ConfirmRow(
                      icon: BootstrapIcons.clock,
                      label: 'Time',
                      value: appointmentTime,
                    ),
                    const Divider(height: 22, color: Color(0xFFF1F5F9)),
                    _ConfirmRow(
                      icon: BootstrapIcons.info_circle_fill,
                      label: 'Status',
                      value: status,
                      valueColor: AppColors.success,
                      valueBold: true,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // ── Action Buttons ────────────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.event_outlined, size: 20),
                  label: const Text(
                    'View Appointment',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () =>
                      context.go('/patient/appointments/$appointmentId'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.home_outlined, size: 20),
                  label: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => context.go('/patient'),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FE),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
