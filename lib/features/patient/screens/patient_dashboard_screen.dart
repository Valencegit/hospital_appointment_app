import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/appointment_model.dart';
import '../../../models/department_model.dart';
import '../../../models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../services/firestore_service.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Metro Health Patient Dashboard — Screen 5.
/// Shows hero header with next appointment, quick actions, department browse,
/// and notification banner.
class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentNavIndex = 0;

  void _onNavTapped(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/patient/departments');
        break;
      case 2:
        context.push('/patient/appointments');
        break;
      case 3:
        context.push('/patient/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final patient = auth.patientProfile;
    final uid = user?.uid ?? '';

    final displayName = patient?.firstName ?? user?.firstName ?? 'Sarah';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Royal Blue Hero Banner ──────────────────────────────────
              _PatientHeroHeader(
                displayName: displayName,
                uid: uid,
                onNotificationTap: () => context.push('/patient/notifications'),
              ),

              const SizedBox(height: 20),
              _PatientAppointmentsOverview(patientId: uid),
              const SizedBox(height: 24),

              // ── Quick Actions 2x2 Grid ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Services',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _QuickActionGrid2x2(
                      onBook: () => context
                          .push('/patient/book', extra: <String, dynamic>{}),
                      onAppointments: () =>
                          context.push('/patient/appointments'),
                      onDepartments: () => context.push('/patient/departments'),
                      onProfile: () => context.push('/patient/profile'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Departments Browse ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Departments',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/patient/departments'),
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
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 106,
                child: StreamBuilder<List<DepartmentModel>>(
                  stream: context
                      .read<DepartmentProvider>()
                      .activeDepartmentsStream(),
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return const Center(
                        child: Text('Unable to load departments.'),
                      );
                    }
                    final depts = snap.data ?? const <DepartmentModel>[];
                    if (depts.isEmpty) {
                      return const Center(
                        child: Text('No departments are currently available.'),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: depts.length.clamp(0, 8),
                      itemBuilder: (_, i) {
                        final d = depts[i];
                        return _DeptChip(
                          name: d.name,
                          icon: _deptIcon(d.name),
                          onTap: () => context.push(
                            '/patient/departments/slots',
                            extra: {
                              'departmentId': d.id,
                              'departmentName': d.name,
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // ── Recent Notifications Banner ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/patient/notifications'),
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
                    StreamBuilder<List<NotificationModel>>(
                      stream: context
                          .read<FirestoreService>()
                          .notificationsStream(uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Unable to load notifications.');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LinearProgressIndicator();
                        }
                        final notifications = snapshot.data ?? const [];
                        if (notifications.isEmpty) {
                          return const Text(
                            'You’re all caught up. No notifications yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          );
                        }
                        return Column(
                          children: notifications.take(2).map((notification) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _NotifBannerTile(
                                icon: notification.isRead
                                    ? Icons.notifications_none
                                    : Icons.notifications_active_rounded,
                                iconBg: AppColors.primaryLight,
                                iconColor: AppColors.primary,
                                title: notification.title,
                                subtitle: notification.body,
                                onTap: () =>
                                    context.push('/patient/notifications'),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _MetroBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTapped,
      ),
    );
  }

  static IconData _deptIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cardio')) { return BootstrapIcons.heart; }
    if (lower.contains('paedia') || lower.contains('pedi')) {
      return BootstrapIcons.emoji_smile;
    }
    if (lower.contains('ortho')) { return BootstrapIcons.universal_access; }
    if (lower.contains('derma')) { return BootstrapIcons.person_bounding_box; }
    if (lower.contains('ophthal')) { return BootstrapIcons.eye; }
    if (lower.contains('dental') || lower.contains('dent')) {
      return BootstrapIcons.bag_plus;
    }
    if (lower.contains('obs') ||
        lower.contains('gynae') ||
        lower.contains('gyne')) { return BootstrapIcons.person_heart; }
    if (lower.contains('neuro')) { return Icons.psychology_outlined; }
    return BootstrapIcons.hospital;
  }
}

/// Royal blue curved hero header containing user greeting and Next Appointment card.
class _PatientAppointmentsOverview extends StatelessWidget {
  final String patientId;
  const _PatientAppointmentsOverview({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: context
          .read<AppointmentProvider>()
          .patientAppointmentsStream(patientId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Unable to load your appointments.'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(),
          );
        }
        final appointments = snapshot.data ?? const <AppointmentModel>[];
        final now = DateTime.now();
        final upcoming = appointments
            .where((appointment) =>
                appointment.appointmentDate.isAfter(now) &&
                !appointment.isCancelled)
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
        final pending =
            appointments.where((appointment) => appointment.isPending).length;
        final completed =
            appointments.where((appointment) => appointment.isCompleted).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PatientMetricCard(
                    label: 'Upcoming',
                    value: upcoming.length,
                  ),
                  const SizedBox(width: 8),
                  _PatientMetricCard(
                    label: 'Pending',
                    value: pending,
                  ),
                  const SizedBox(width: 8),
                  _PatientMetricCard(
                    label: 'Completed',
                    value: completed,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Next appointment',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (upcoming.isEmpty)
                const Text(
                  'You have no upcoming appointments.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                Card(
                  child: ListTile(
                    title: Text(upcoming.first.departmentName),
                    subtitle: Text(
                      '${DateFormat('EEE, MMM d').format(upcoming.first.appointmentDate)} · '
                      '${upcoming.first.appointmentTime}\n'
                      '${upcoming.first.doctorName ?? 'Doctor to be assigned'}',
                    ),
                    isThreeLine: true,
                    trailing: Text(upcoming.first.status),
                    onTap: () => context.push(
                      '/patient/appointments/${upcoming.first.id}',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PatientMetricCard extends StatelessWidget {
  final String label;
  final int value;

  const _PatientMetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PatientHeroHeader extends StatelessWidget {
  final String displayName;
  final String uid;
  final VoidCallback onNotificationTap;

  const _PatientHeroHeader({
    required this.displayName,
    required this.uid,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF008F87),
            Color(0xFF006D68),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Greeting & Notification Bell
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: Container(
                    color: AppColors.primaryLight,
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User Name & Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $displayName!',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Patient',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD6E6FF),
                      ),
                    ),
                  ],
                ),
              ),
              // Notification Bell
              GestureDetector(
                onTap: onNotificationTap,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      BootstrapIcons.bell,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Next Appointment Hero Card
          StreamBuilder<List<AppointmentModel>>(
            stream: context
                .read<AppointmentProvider>()
                .patientAppointmentsStream(uid),
            builder: (ctx, snap) {
              final appointments = snap.data ?? [];
              final upcoming = appointments
                  .where(
                    (a) =>
                        (a.isPending || a.isConfirmed) &&
                        a.appointmentDate.isAfter(DateTime.now()),
                  )
                  .toList()
                ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

              final appt = upcoming.isNotEmpty ? upcoming.first : null;
              final dateStr = appt != null
                  ? DateFormat('EEE, MMM d, yyyy • h:mm a')
                      .format(appt.appointmentDate)
                  : 'No upcoming appointments';
              final deptName =
                  appt?.departmentName ?? 'Book a visit to see it here.';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next Appointment',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFE0ECFF),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              deptName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFB9D7FF),
                              ),
                            ),
                          ],
                        ),
                        // Calendar Icon Box
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            BootstrapIcons.calendar_fill,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        if (appt != null) {
                          context.push('/patient/appointments/${appt.id}');
                        } else {
                          context.push('/patient/book');
                        }
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            BootstrapIcons.chevron_right,
                            size: 11,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 2x2 Clean Rounded White Cards with soft light blue icon boxes matching the mockup.
class _QuickActionGrid2x2 extends StatelessWidget {
  final VoidCallback onBook;
  final VoidCallback onAppointments;
  final VoidCallback onDepartments;
  final VoidCallback onProfile;

  const _QuickActionGrid2x2({
    required this.onBook,
    required this.onAppointments,
    required this.onDepartments,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        _QuickActionCard(
          icon: BootstrapIcons.calendar_fill,
          title: 'Book\nAppointment',
          onTap: onBook,
        ),
        _QuickActionCard(
          icon: BootstrapIcons.clipboard,
          title: 'My\nAppointments',
          onTap: onAppointments,
        ),
        _QuickActionCard(
          icon: BootstrapIcons.hospital,
          title: 'Departments',
          onTap: onDepartments,
        ),
        _QuickActionCard(
          icon: BootstrapIcons.person,
          title: 'Profile',
          onTap: onProfile,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE9F0FA), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF7F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
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

/// Standard 4-item bottom navigation bar for Metro Health patient flow.
class _MetroBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MetroBottomNav({
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
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.bell),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling department chip for the dashboard browse strip.
class _DeptChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;

  const _DeptChip({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EBF7), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF7F4),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    );
  }
}

/// Notification banner tile shown on the dashboard.
class _NotifBannerTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NotifBannerTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2EBF7), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                BootstrapIcons.chevron_right,
                size: 13,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
