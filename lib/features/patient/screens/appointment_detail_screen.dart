import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../services/appointment_service.dart';
import '../../../shared/widgets/custom_button.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppointmentModel?>(
      future: context.read<AppointmentService>().getAppointment(appointmentId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final appt = snap.data;
        if (appt == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Appointment')),
            body: const Center(child: Text('Appointment not found.')),
          );
        }
        return _DetailView(appointment: appt);
      },
    );
  }
}

class _DetailView extends StatefulWidget {
  final AppointmentModel appointment;
  const _DetailView({required this.appointment});

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  AppointmentModel get a => widget.appointment;

  void _showRescheduleDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request Reschedule'),
        content: const Text(
          'A reschedule request will be submitted to hospital staff. '
          'They will contact you with available alternative slots.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context
                  .read<AppointmentProvider>()
                  .updateStatus(a.id, AppConstants.statusRescheduleRequested);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Reschedule request submitted.'
                      : 'Failed to submit request.'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ));
                if (ok) Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Request Cancellation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason:',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Enter reason for cancellation...'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              final ok = await context
                  .read<AppointmentProvider>()
                  .requestCancellation(a.id, _reasonCtrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Cancellation request submitted.'
                      : 'Failed to submit request.'),
                  backgroundColor:
                      ok ? AppColors.success : AppColors.error,
                ));
                if (ok) Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apptProvider = context.watch<AppointmentProvider>();
    final statusBg = _statusBg(a.status);
    final statusFg = _statusFg(a.status);

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
                    // Status header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius),
                      ),
                      child: Column(
                        children: [
                          const Icon(BootstrapIcons.bag_plus,
                              color: Colors.white54, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            a.departmentName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(a.status),
                              style: TextStyle(
                                color: statusFg,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _InfoCard(children: [
                      _Row('Reference',
                          a.id.substring(0, 8).toUpperCase()),
                      const Divider(height: 20),
                      _Row('Date',
                          DateFormat('EEEE, MMMM d, yyyy')
                              .format(a.appointmentDate)),
                      const Divider(height: 20),
                      _Row('Time', a.appointmentTime),
                      const Divider(height: 20),
                      _Row('Booked on',
                          DateFormat('MMM d, yyyy, h:mm a')
                              .format(a.bookedAt)),
                    ]),

                    if (a.notes != null && a.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Notes',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      _InfoCard(children: [
                        Text(a.notes!,
                            style: const TextStyle(height: 1.5))
                      ]),
                    ],

                    if (a.cancellationReason != null) ...[
                      const SizedBox(height: 16),
                      const Text('Cancellation Reason',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.error)),
                      const SizedBox(height: 8),
                      _InfoCard(children: [
                        Text(a.cancellationReason!,
                            style: const TextStyle(height: 1.5))
                      ]),
                    ],

                    if (a.isPending || a.isConfirmed) ...[
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Request Reschedule',
                        variant: ButtonVariant.outlined,
                        icon: Icons.edit_calendar_outlined,
                        onPressed: _showRescheduleDialog,
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        text: 'Request Cancellation',
                        variant: ButtonVariant.danger,
                        icon: BootstrapIcons.x_circle,
                        onPressed: _showCancelDialog,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case AppConstants.statusPending:
        return 'Pending Confirmation';
      case AppConstants.statusConfirmed:
        return 'Confirmed';
      case AppConstants.statusCancelled:
        return 'Cancelled';
      case AppConstants.statusCompleted:
        return 'Completed';
      case AppConstants.statusCancelRequested:
        return 'Cancellation Requested';
      case AppConstants.statusRescheduleRequested:
        return 'Reschedule Requested';
      default:
        return s;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
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

  Color _statusFg(String s) {
    switch (s) {
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

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
