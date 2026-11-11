import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Screen 14: Manage Appointments — searchable, filterable list for staff.
class StaffAppointmentsScreen extends StatefulWidget {
  const StaffAppointmentsScreen({super.key});

  @override
  State<StaffAppointmentsScreen> createState() =>
      _StaffAppointmentsScreenState();
}

class _StaffAppointmentsScreenState extends State<StaffAppointmentsScreen> {
  String _statusFilter = 'all';
  DateTime? _dateFilter;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _statuses = [
    ('all', 'All'),
    (AppConstants.statusPending, 'Pending'),
    (AppConstants.statusConfirmed, 'Confirmed'),
    (AppConstants.statusCancelRequested, 'Cancel Req.'),
    (AppConstants.statusRescheduleRequested, 'Reschedule Req.'),
    (AppConstants.statusCompleted, 'Completed'),
    (AppConstants.statusCancelled, 'Cancelled'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(BootstrapIcons.calendar_range),
            tooltip: 'Filter by date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search by patient name or reference...',
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Status filters ──────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (value, label) = _statuses[i];
                  final selected = _statusFilter == value;
                  return FilterChip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() => _statusFilter = value),
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              ),
            ),
          ),

          // Active date filter banner
          if (_dateFilter != null)
            Container(
              color: AppColors.infoLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(BootstrapIcons.calendar_date,
                      size: 14, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(
                    'Filtered: ${DateFormat('EEE, MMM d').format(_dateFilter!)}',
                    style: const TextStyle(color: AppColors.info, fontSize: 13),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _dateFilter = null),
                    child: const Icon(BootstrapIcons.x_lg,
                        size: 16, color: AppColors.info),
                  ),
                ],
              ),
            ),

          // ── Appointment list ────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
              stream: context.watch<AuthProvider>().currentRole.isDoctor
                  ? context
                      .read<AppointmentProvider>()
                      .doctorAppointmentsStream(
                        context.read<AuthProvider>().currentUser!.uid,
                      )
                  : context.read<AppointmentProvider>().allAppointmentsStream(
                        status: _statusFilter == 'all' ? null : _statusFilter,
                        date: _dateFilter,
                      ),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var appointments = snap.data ?? [];
                final isDoctor =
                    context.read<AuthProvider>().currentRole.isDoctor;
                if (isDoctor && _statusFilter != 'all') {
                  appointments = appointments
                      .where((a) => a.status == _statusFilter)
                      .toList();
                }
                if (isDoctor && _dateFilter != null) {
                  appointments = appointments
                      .where((a) =>
                          a.appointmentDate.year == _dateFilter!.year &&
                          a.appointmentDate.month == _dateFilter!.month &&
                          a.appointmentDate.day == _dateFilter!.day)
                      .toList();
                }

                // Client-side search filter
                if (_searchQuery.isNotEmpty) {
                  appointments = appointments
                      .where((a) =>
                          a.patientName.toLowerCase().contains(_searchQuery) ||
                          a.id.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (appointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(BootstrapIcons.calendar_x,
                            size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery"'
                              : 'No appointments found',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: appointments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _StaffApptTile(appointment: appointments[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dateFilter = picked);
  }
}

class _StaffApptTile extends StatelessWidget {
  final AppointmentModel appointment;
  const _StaffApptTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(BootstrapIcons.person,
              color: AppColors.primary, size: 20),
        ),
        title: Text(appointment.patientName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(appointment.departmentName,
                style: const TextStyle(color: AppColors.primary, fontSize: 12)),
            Text(
              '${DateFormat('MMM d, yyyy').format(appointment.appointmentDate)}  ·  ${appointment.appointmentTime}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        trailing: _StatusBadge(status: appointment.status),
        onTap: () => context.push('/staff/appointments/${appointment.id}'),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

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
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        _label(status),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _label(String s) {
    switch (s) {
      case AppConstants.statusPending:
        return 'Pending';
      case AppConstants.statusConfirmed:
        return 'Confirmed';
      case AppConstants.statusCancelled:
        return 'Cancelled';
      case AppConstants.statusCompleted:
        return 'Completed';
      case AppConstants.statusCancelRequested:
        return 'Cancel Req.';
      default:
        return s;
    }
  }
}
