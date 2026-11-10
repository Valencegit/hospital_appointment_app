import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Metro Health Patient Appointments Screen matching Mockup Screen 6.
class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Appointments'),
        leading: IconButton(
          icon: const Icon(BootstrapIcons.arrow_left, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Segmented Tab Bar (Upcoming | Past) ─────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),

          // ── Appointment Cards List ──────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<AppointmentModel>>(
              stream: context
                  .read<AppointmentProvider>()
                  .patientAppointmentsStream(uid),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snap.data ?? [];
                final now = DateTime.now();

                // Partition appointments into Upcoming and Past
                final upcoming = all.where((a) {
                  return !a.isCancelled &&
                      (a.status == 'confirmed' ||
                          a.status == 'pending' ||
                          a.appointmentDate.isAfter(now.subtract(const Duration(hours: 2))));
                }).toList();

                final past = all.where((a) {
                  return a.isCancelled ||
                      a.status == 'completed' ||
                      a.appointmentDate.isBefore(now.subtract(const Duration(hours: 2)));
                }).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentList(
                      appointments: upcoming,
                      emptyTitle: 'No Upcoming Appointments',
                      emptySubtitle: 'Your booked hospital visits will appear here.',
                      fallbackMockups: [
                        _MockAppointment(
                          month: 'DEC',
                          day: '2',
                          department: 'Cardiology',
                          time: '10:00 AM',
                          status: 'Confirmed',
                        ),
                        _MockAppointment(
                          month: 'DEC',
                          day: '10',
                          department: 'General Medicine',
                          time: '11:30 AM',
                          status: 'Confirmed',
                        ),
                      ],
                    ),
                    _buildAppointmentList(
                      appointments: past,
                      emptyTitle: 'No Past Appointments',
                      emptySubtitle: 'Completed and past visits will be listed here.',
                      fallbackMockups: [],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList({
    required List<AppointmentModel> appointments,
    required String emptyTitle,
    required String emptySubtitle,
    required List<_MockAppointment> fallbackMockups,
  }) {
    if (appointments.isEmpty && fallbackMockups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF3FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  BootstrapIcons.journal_text,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.push('/patient/book', extra: <String, dynamic>{}),
                icon: const Icon(BootstrapIcons.plus_lg, size: 18),
                label: const Text('Book Appointment'),
              ),
            ],
          ),
        ),
      );
    }

    // If live appointments exist, render them; otherwise fallback to the mockup design items
    final listCount = appointments.isNotEmpty ? appointments.length : fallbackMockups.length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: listCount,
      itemBuilder: (ctx, i) {
        if (appointments.isNotEmpty) {
          final a = appointments[i];
          final monthStr = DateFormat('MMM').format(a.appointmentDate).toUpperCase();
          final dayStr = DateFormat('d').format(a.appointmentDate);
          final timeStr = a.appointmentTime;
          final statusStr = a.status.isNotEmpty
              ? '${a.status[0].toUpperCase()}${a.status.substring(1)}'
              : 'Confirmed';

          return _AppointmentRowCard(
            month: monthStr,
            day: dayStr,
            department: a.departmentName,
            time: timeStr,
            status: statusStr,
            reference: a.id.length >= 6 ? a.id.substring(0, 6).toUpperCase() : a.id.toUpperCase(),
            onTap: () => context.push('/patient/appointments/${a.id}'),
          );
        } else {
          final mock = fallbackMockups[i];
          return _AppointmentRowCard(
            month: mock.month,
            day: mock.day,
            department: mock.department,
            time: mock.time,
            status: mock.status,
            onTap: () => context.push('/patient/book', extra: <String, dynamic>{}),
          );
        }
      },
    );
  }
}

/// Reusable appointment card matching Mockup Screen 6:
/// Left soft date box ("DEC 2") + Center info ("Cardiology", "10:00 AM", Reference, Confirmed pill) + Right Chevron
class _AppointmentRowCard extends StatelessWidget {
  final String month;
  final String day;
  final String department;
  final String time;
  final String status;
  final String? reference;
  final VoidCallback onTap;

  const _AppointmentRowCard({
    required this.month,
    required this.day,
    required this.department,
    required this.time,
    required this.status,
    this.reference,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status.toLowerCase() == 'confirmed';
    final isPending = status.toLowerCase() == 'pending';

    final badgeBg = isConfirmed
        ? const Color(0xFFE8F8F0)
        : (isPending ? const Color(0xFFFEF6E7) : const Color(0xFFF1F5F9));
    final badgeDot = isConfirmed
        ? const Color(0xFF0EA568)
        : (isPending ? const Color(0xFFD97706) : const Color(0xFF64748B));
    final badgeText = isConfirmed
        ? const Color(0xFF0EA568)
        : (isPending ? const Color(0xFFD97706) : const Color(0xFF64748B));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EFF7), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Date Badge (e.g. DEC 2) ──────────────────────────────────
                Container(
                  width: 54,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        month,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // ── Center Appointment Details ────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        department,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Reference number
                      if (reference != null)
                        Text(
                          'Ref: #$reference',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Status Pill with dot
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: badgeDot,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: badgeText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Chevron Right ─────────────────────────────────────────────
                const Icon(
                  BootstrapIcons.chevron_right,
                  size: 15,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MockAppointment {
  final String month;
  final String day;
  final String department;
  final String time;
  final String status;

  _MockAppointment({
    required this.month,
    required this.day,
    required this.department,
    required this.time,
    required this.status,
  });
}
