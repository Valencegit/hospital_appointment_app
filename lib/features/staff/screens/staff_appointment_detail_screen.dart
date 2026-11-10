import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../../../services/appointment_service.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/custom_button.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class StaffAppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;

  const StaffAppointmentDetailScreen(
      {super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppointmentModel?>(
      future:
          context.read<AppointmentService>().getAppointment(appointmentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final appt = snap.data;
        if (appt == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Appointment')),
            body: const Center(child: Text('Not found.')),
          );
        }
        return _StaffDetailView(appointment: appt);
      },
    );
  }
}

class _StaffDetailView extends StatefulWidget {
  final AppointmentModel appointment;
  const _StaffDetailView({required this.appointment});

  @override
  State<_StaffDetailView> createState() => _StaffDetailViewState();
}

class _StaffDetailViewState extends State<_StaffDetailView> {
  AppointmentModel get a => widget.appointment;

  Future<void> _updateStatus(String newStatus) async {
    final actorUid =
        context.read<AuthProvider>().currentUser?.uid ?? '';

    final ok = await context
        .read<AppointmentProvider>()
        .updateStatus(a.id, newStatus);

    if (mounted) {
      if (ok) {
        // Write audit log
        context.read<FirestoreService>().writeAuditLog(
          actorUid: actorUid,
          action: 'appointment_status_set_to_$newStatus',
          recordRef: a.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Status updated to ${newStatus.replaceAll('_', ' ')}.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = context.watch<AppointmentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: SafeArea(
        child: apptProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              a.patientName.isNotEmpty
                                  ? a.patientName[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(a.patientName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(a.departmentName,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          _StatusChip(status: a.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Details
                    _InfoRow('Ref #',
                        a.id.substring(0, 8).toUpperCase()),
                    _InfoRow('Date',
                        DateFormat('EEE, MMM d, yyyy')
                            .format(a.appointmentDate)),
                    _InfoRow('Time', a.appointmentTime),
                    _InfoRow('Booked On',
                        DateFormat('MMM d, yyyy h:mm a')
                            .format(a.bookedAt)),

                    if (a.notes != null && a.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _InfoRow('Notes', a.notes!),
                    ],
                    if (a.cancellationReason != null) ...[
                      const SizedBox(height: 4),
                      _InfoRow('Cancel Reason', a.cancellationReason!),
                    ],

                    const SizedBox(height: 28),
                    const Text('Update Status',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 12),

                    // Action buttons based on current status
                    if (a.isPending) ...[
                      CustomButton(
                        text: 'Confirm Appointment',
                        icon: BootstrapIcons.check_circle,
                        onPressed: () => _updateStatus(
                            AppConstants.statusConfirmed),
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        text: 'Cancel Appointment',
                        variant: ButtonVariant.danger,
                        icon: BootstrapIcons.x_circle,
                        onPressed: () => _updateStatus(
                            AppConstants.statusCancelled),
                      ),
                    ],
                    if (a.isConfirmed) ...[
                      CustomButton(
                        text: 'Mark as Completed',
                        icon: BootstrapIcons.check_all,
                        onPressed: () => _updateStatus(
                            AppConstants.statusCompleted),
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        text: 'Cancel Appointment',
                        variant: ButtonVariant.danger,
                        icon: BootstrapIcons.x_circle,
                        onPressed: () => _updateStatus(
                            AppConstants.statusCancelled),
                      ),
                    ],
                    if (a.status ==
                        AppConstants.statusCancelRequested) ...[
                      CustomButton(
                        text: 'Approve Cancellation',
                        variant: ButtonVariant.danger,
                        icon: BootstrapIcons.check,
                        onPressed: () => _updateStatus(
                            AppConstants.statusCancelled),
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        text: 'Reject — Keep Confirmed',
                        variant: ButtonVariant.outlined,
                        onPressed: () => _updateStatus(
                            AppConstants.statusConfirmed),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case AppConstants.statusPending:
        bg = AppColors.statusPending;
        fg = AppColors.statusPendingText;
        break;
      case AppConstants.statusConfirmed:
        bg = AppColors.statusConfirmed;
        fg = AppColors.statusConfirmedText;
        break;
      case AppConstants.statusCancelled:
        bg = AppColors.statusCancelled;
        fg = AppColors.statusCancelledText;
        break;
      case AppConstants.statusCompleted:
        bg = AppColors.statusCompleted;
        fg = AppColors.statusCompletedText;
        break;
      default:
        bg = Colors.white24;
        fg = Colors.white;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
            color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
