import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/appointment_provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Screen 21 (Admin) / Screen 17 (Staff): Reports — appointment summaries
/// with status breakdown and date-range filter.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _dateRange;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          TextButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(BootstrapIcons.calendar_range,
                color: Colors.white, size: 18),
            label: Text(
              _dateRange == null
                  ? 'Date Range'
                  : '${DateFormat('d MMM').format(_dateRange!.start)} – '
                      '${DateFormat('d MMM').format(_dateRange!.end)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: context.read<AppointmentProvider>().getSummary(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data ?? {};
          final total = d['total'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              // ── Date range chip ───────────────────────────────────────────
              if (_dateRange != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Filtered: ${DateFormat('d MMM yyyy').format(_dateRange!.start)}'
                        ' – ${DateFormat('d MMM yyyy').format(_dateRange!.end)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _dateRange = null),
                        child: const Icon(BootstrapIcons.x_lg,
                            size: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),

              const Text(
                'Appointment Summary',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // ── Total card ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius),
                ),
                child: Row(
                  children: [
                    const Icon(BootstrapIcons.calendar,
                        color: Colors.white54, size: 44),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Text(
                          'Total Appointments',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Status breakdown ──────────────────────────────────────────
              const Text(
                'Status Breakdown',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _StatusCard(
                label: 'Pending',
                value: d[AppConstants.statusPending] ?? 0,
                total: total,
                color: AppColors.warning,
                icon: BootstrapIcons.hourglass,
              ),
              const SizedBox(height: 10),
              _StatusCard(
                label: 'Confirmed',
                value: d[AppConstants.statusConfirmed] ?? 0,
                total: total,
                color: AppColors.success,
                icon: BootstrapIcons.check_circle,
              ),
              const SizedBox(height: 10),
              _StatusCard(
                label: 'Completed',
                value: d[AppConstants.statusCompleted] ?? 0,
                total: total,
                color: AppColors.info,
                icon: BootstrapIcons.check_all,
              ),
              const SizedBox(height: 10),
              _StatusCard(
                label: 'Cancelled',
                value: d[AppConstants.statusCancelled] ?? 0,
                total: total,
                color: AppColors.error,
                icon: BootstrapIcons.x_circle,
              ),
              const SizedBox(height: 10),
              _StatusCard(
                label: 'Reschedule Requested',
                value: d[AppConstants.statusRescheduleRequested] ?? 0,
                total: total,
                color: const Color(0xFF7C3AED),
                icon: Icons.edit_calendar_outlined,
              ),

              if (total > 0) ...[
                const SizedBox(height: 24),
                const Text(
                  'Completion Rate',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _ProgressRow(
                  label: 'Completed',
                  value: (d[AppConstants.statusCompleted] ?? 0) / total,
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                _ProgressRow(
                  label: 'Cancelled',
                  value:
                      (d[AppConstants.statusCancelled] ?? 0) / total,
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                _ProgressRow(
                  label: 'Pending',
                  value: (d[AppConstants.statusPending] ?? 0) / total,
                  color: AppColors.warning,
                ),
              ],

              const SizedBox(height: 24),

              // ── Department breakdown (placeholder) ────────────────────────
              const Text(
                'By Department',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ..._deptBreakdown.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _DeptReportTile(
                      name: e.$1,
                      count: e.$2,
                      totalForBar: 120,
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  // Placeholder department data — will be replaced with Firestore queries
  static const _deptBreakdown = [
    ('Cardiology', 38),
    ('General Medicine', 32),
    ('Paediatrics', 22),
    ('Orthopaedics', 18),
    ('Dermatology', 10),
  ];
}

class _StatusCard extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0
        ? (value / total * 100).toStringAsFixed(1)
        : '0.0';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius:
            BorderRadius.circular(AppConstants.defaultBorderRadius),
        border:
            Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500)),
          ),
          Text('$pct%',
              style: TextStyle(
                  color: color,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Text('$value',
              style: TextStyle(
                  color: color,
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toStringAsFixed(1);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            Text('$pct%',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _DeptReportTile extends StatelessWidget {
  final String name;
  final int count;
  final int totalForBar;

  const _DeptReportTile({
    required this.name,
    required this.count,
    required this.totalForBar,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = totalForBar > 0 ? count / totalForBar : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$count appointments',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.1),
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
