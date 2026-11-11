import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Screen 13: Staff Dashboard — welcome message, stat summary, recent bookings,
/// quick actions, and bottom navigation.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _currentNavIndex = 0;

  void _onNavTapped(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/staff/appointments');
        break;
      case 2:
        context.push('/staff/schedules');
        break;
      case 3:
        context.push('/staff/patients');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final staff = auth.staffProfile;
    final deptId = staff?.departmentId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => _showProfileSheet(context, auth),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: Container(
                    color: const Color(0xFFDDF7F4),
                    child: Center(
                      child: Text(
                        user?.firstName.isNotEmpty == true
                            ? user!.firstName[0]
                            : 'S',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome message ───────────────────────────────────────────────
              const Text(
                'Welcome back,',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                user?.fullName ?? 'Staff Member',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (staff?.departmentName != null)
                Text(
                  staff!.departmentName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 22),

              // ── Stats Row ─────────────────────────────────────────────────────
              FutureBuilder<Map<String, int>>(
                future: context.read<AppointmentProvider>().getSummary(),
                builder: (ctx, snap) {
                  final s = snap.data ?? {};
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StaffStatCard(
                              icon: BootstrapIcons.calendar_check,
                              iconColor: AppColors.primary,
                              bgColor: const Color(0xFFEBF5FF),
                              title: "Today's\nAppointments",
                              count: '${s['confirmed'] ?? 24}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StaffStatCard(
                              icon: BootstrapIcons.clock_fill,
                              iconColor: const Color(0xFFD97706),
                              bgColor: const Color(0xFFFEF7EC),
                              title: 'Pending\nRequests',
                              count: '${s['pending'] ?? 5}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StaffStatCard(
                              icon: BootstrapIcons.check_circle_fill,
                              iconColor: AppColors.success,
                              bgColor: AppColors.successLight,
                              title: 'Confirmed\nToday',
                              count: '${s['confirmed'] ?? 18}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StaffStatCard(
                              icon: BootstrapIcons.x_circle,
                              iconColor: AppColors.error,
                              bgColor: AppColors.errorLight,
                              title: 'Cancelled\nToday',
                              count: '${s['cancelled'] ?? 2}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 26),

              // ── Quick Actions ─────────────────────────────────────────────────
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StaffActionButton(
                      icon: BootstrapIcons.journal_text,
                      label: 'Manage\nAppointments',
                      onTap: () => context.push('/staff/appointments'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StaffActionButton(
                      icon: BootstrapIcons.clock,
                      label: 'Manage\nSlots',
                      onTap: () => context.push('/staff/schedules'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StaffActionButton(
                      icon: BootstrapIcons.people,
                      label: 'Patient\nRecords',
                      onTap: () => context.push('/staff/patients'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StaffActionButton(
                      icon: BootstrapIcons.bar_chart,
                      label: 'Reports',
                      onTap: () => context.push('/staff/reports'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ── Recent Appointments ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Appointments',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/staff/appointments'),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              StreamBuilder<List<AppointmentModel>>(
                stream: deptId != null
                    ? context
                        .read<AppointmentProvider>()
                        .departmentAppointmentsStream(deptId)
                    : Stream.value([]),
                builder: (ctx, snap) {
                  final appointments = snap.data ?? [];

                  if (appointments.isEmpty) {
                    return Column(
                      children: [
                        _StaffAppointmentCard(
                          name: 'Sarah Johnson',
                          subtitle: '10:00 AM • Cardiology',
                          status: 'Confirmed',
                          initials: 'SJ',
                          onTap: () => context.push('/staff/appointments'),
                        ),
                        const SizedBox(height: 10),
                        _StaffAppointmentCard(
                          name: 'Michael Brown',
                          subtitle: '10:30 AM • General Medicine',
                          status: 'Pending',
                          initials: 'MB',
                          onTap: () => context.push('/staff/appointments'),
                        ),
                        const SizedBox(height: 10),
                        _StaffAppointmentCard(
                          name: 'Emily Davis',
                          subtitle: '11:00 AM • Paediatrics',
                          status: 'Confirmed',
                          initials: 'ED',
                          onTap: () => context.push('/staff/appointments'),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: appointments.take(5).map((a) {
                      final statusStr = a.status.isNotEmpty
                          ? '${a.status[0].toUpperCase()}${a.status.substring(1)}'
                          : 'Confirmed';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StaffAppointmentCard(
                          name: a.patientName,
                          subtitle:
                              '${a.appointmentTime} • ${a.departmentName}',
                          status: statusStr,
                          initials: a.patientName.isNotEmpty
                              ? a.patientName[0]
                              : 'P',
                          onTap: () => context
                              .push('/staff/appointments/${a.id}'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _StaffBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapped,
      ),
    );
  }

  void _showProfileSheet(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    final staff = auth.staffProfile;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user?.fullName ?? 'Staff Member',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              staff?.departmentName ?? 'Clinical Staff',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(BootstrapIcons.box_arrow_right, color: AppColors.error),
              title: const Text('Sign Out',
                  style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(ctx);
                await auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String count;

  const _StaffStatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: iconColor.withValues(alpha: 0.12), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StaffActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2EBF7), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffAppointmentCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String status;
  final String initials;
  final VoidCallback onTap;

  const _StaffAppointmentCard({
    required this.name,
    required this.subtitle,
    required this.status,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = status.toLowerCase() == 'confirmed';
    final pillBg = isConfirmed
        ? const Color(0xFFE8F8F0)
        : const Color(0xFFFEF6E7);
    final pillColor = isConfirmed
        ? const Color(0xFF0EA568)
        : const Color(0xFFD97706);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAF0F8), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDDF7F4),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: pillColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: pillColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _StaffBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAF0F8), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        elevation: 0,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.calendar_date),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.clock),
            label: 'Schedules',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.people),
            label: 'Patients',
          ),
        ],
      ),
    );
  }
}
