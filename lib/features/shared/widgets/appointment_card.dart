import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/appointment_model.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Reusable appointment card widget showing key appointment details and status.
class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusBgColor(appointment.status);
    final statusTextColor = _statusTextColor(appointment.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date column
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd').format(appointment.appointmentDate),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(appointment.appointmentDate),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.departmentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(BootstrapIcons.clock,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        appointment.appointmentTime,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(appointment.status),
                style: TextStyle(
                  color: statusTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusConfirmed:
        return 'Confirmed';
      case AppConstants.statusCancelled:
        return 'Cancelled';
      case AppConstants.statusCompleted:
        return 'Completed';
      case AppConstants.statusRescheduled:
        return 'Rescheduled';
      case AppConstants.statusCancelRequested:
        return 'Cancel Req.';
      case AppConstants.statusRescheduleRequested:
        return 'Reschedule Req.';
      default:
        return status;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppColors.statusPending;
      case AppConstants.statusConfirmed:
        return AppColors.statusConfirmed;
      case AppConstants.statusCancelled:
        return AppColors.statusCancelled;
      case AppConstants.statusCompleted:
        return AppColors.statusCompleted;
      default:
        return AppColors.surfaceVariant;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return AppColors.statusPendingText;
      case AppConstants.statusConfirmed:
        return AppColors.statusConfirmedText;
      case AppConstants.statusCancelled:
        return AppColors.statusCancelledText;
      case AppConstants.statusCompleted:
        return AppColors.statusCompletedText;
      default:
        return AppColors.textSecondary;
    }
  }
}
