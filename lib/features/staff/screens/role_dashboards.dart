import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/appointment_model.dart';
import '../../../models/department_model.dart';
import '../../../models/slot_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/department_provider.dart';
import '../../../shared/widgets/app_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. RECEPTIONIST DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

/// Front-desk appointment queue with today's stats and quick actions.
class ReceptionistDashboardScreen extends StatefulWidget {
  const ReceptionistDashboardScreen({super.key});

  @override
  State<ReceptionistDashboardScreen> createState() =>
      _ReceptionistDashboardScreenState();
}

class _ReceptionistDashboardScreenState
    extends State<ReceptionistDashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _RoleAppBar(
            title: 'Reception',
            subtitle: user?.fullName ?? 'Receptionist',
            roleColor: AppColors.roleReceptionist,
            roleLabel: 'Front Desk',
            onSignOut: () => _signOut(context, auth),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Today's stats ─────────────────────────────────────────
                StreamBuilder<List<AppointmentModel>>(
                  stream: context
                      .read<AppointmentProvider>()
                      .allAppointmentsStream(date: DateTime.now()),
                  builder: (ctx, snap) {
                    final list = snap.data ?? [];
                    final pending = list.where((a) => a.isPending).length;
                    final confirmed = list.where((a) => a.isConfirmed).length;
                    final cancelled = list.where((a) => a.isCancelled).length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Today\'s Queue'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatTile(
                              label: 'Total',
                              value: list.length,
                              color: AppColors.primary,
                              icon: Icons.calendar_today_rounded,
                            ),
                            _StatTile(
                              label: 'Pending',
                              value: pending,
                              color: AppColors.warning,
                              icon: Icons.hourglass_empty_rounded,
                            ),
                            _StatTile(
                              label: 'Confirmed',
                              value: confirmed,
                              color: AppColors.success,
                              icon: Icons.check_circle_outline,
                            ),
                            _StatTile(
                              label: 'Cancelled',
                              value: cancelled,
                              color: AppColors.error,
                              icon: Icons.cancel_outlined,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 22),

                // ── Quick actions ─────────────────────────────────────────
                const _SectionLabel('Quick Actions'),
                const SizedBox(height: 10),
                _QuickActionGrid(actions: [
                  _QuickAction(
                    label: 'Appointment\nQueue',
                    icon: Icons.event_note_outlined,
                    color: AppColors.primary,
                    onTap: () => context.push('/staff/appointments'),
                  ),
                  _QuickAction(
                    label: 'Patient\nSearch',
                    icon: Icons.person_search_outlined,
                    color: AppColors.secondary,
                    onTap: () => context.push('/staff/patients'),
                  ),
                ]),

                const SizedBox(height: 22),

                // ── Recent bookings ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel('Recent Bookings'),
                    TextButton(
                      onPressed: () => context.push('/staff/appointments'),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<AppointmentModel>>(
                  stream: context
                      .read<AppointmentProvider>()
                      .allAppointmentsStream(date: DateTime.now()),
                  builder: (ctx, snap) {
                    final list = (snap.data ?? []).take(5).toList();
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (list.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.event_busy_outlined,
                        message: 'No appointments today.',
                      );
                    }
                    return Column(
                      children: list
                          .map((a) => _AppointmentListTile(
                                appointment: a,
                                onTap: () =>
                                    context.push('/staff/appointments/${a.id}'),
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _StaffBottomNav(
        currentIndex: _navIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded), label: 'Patients'),
        ],
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) context.push('/staff/appointments');
          if (i == 2) context.push('/staff/patients');
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    await auth.signOut();
    if (context.mounted) context.go('/login');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. DOCTOR DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

/// Doctor's view: assigned patients, today's schedule, completed count.
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final staff = auth.staffProfile;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _RoleAppBar(
            title: 'Doctor Dashboard',
            subtitle: user?.fullName ?? 'Doctor',
            roleColor: AppColors.roleDoctor,
            roleLabel: staff?.departmentName ?? 'Clinical',
            onSignOut: () => _signOut(context, auth),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── My stats ──────────────────────────────────────────────
                StreamBuilder<List<AppointmentModel>>(
                  stream: context
                      .read<AppointmentProvider>()
                      .doctorAppointmentsStream(uid),
                  builder: (ctx, snap) {
                    final list = snap.data ?? [];
                    final waiting =
                        list.where((a) => a.isPending || a.isConfirmed).length;
                    final done = list.where((a) => a.isCompleted).length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('My Summary'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatTile(
                              label: 'Assigned',
                              value: list.length,
                              color: AppColors.roleDoctor,
                              icon: Icons.assignment_ind_outlined,
                            ),
                            _StatTile(
                              label: 'Waiting',
                              value: waiting,
                              color: AppColors.warning,
                              icon: Icons.pending_outlined,
                            ),
                            _StatTile(
                              label: 'Done',
                              value: done,
                              color: AppColors.success,
                              icon: Icons.done_all_outlined,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 22),

                // ── Quick actions ─────────────────────────────────────────
                const _SectionLabel('Quick Actions'),
                const SizedBox(height: 10),
                _QuickActionGrid(actions: [
                  _QuickAction(
                    label: 'My\nAppointments',
                    icon: Icons.event_note_outlined,
                    color: AppColors.roleDoctor,
                    onTap: () => context.push('/staff/appointments'),
                  ),
                  _QuickAction(
                    label: 'Manage\nSlots',
                    icon: Icons.schedule_outlined,
                    color: AppColors.primary,
                    onTap: () => context.push('/staff/schedules'),
                  ),
                  _QuickAction(
                    label: 'Patient\nRecords',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.secondary,
                    onTap: () => context.push('/staff/patients'),
                  ),
                ]),

                const SizedBox(height: 22),

                // ── Next patients ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel('Next Patients'),
                    TextButton(
                      onPressed: () => context.push('/staff/appointments'),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<AppointmentModel>>(
                  stream: context
                      .read<AppointmentProvider>()
                      .doctorAppointmentsStream(uid),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = (snap.data ?? [])
                        .where((a) => a.isPending || a.isConfirmed)
                        .take(5)
                        .toList();
                    if (list.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.event_available_outlined,
                        message: 'No upcoming appointments assigned to you.',
                      );
                    }
                    return Column(
                      children: list
                          .map((a) => _AppointmentListTile(
                                appointment: a,
                                onTap: () =>
                                    context.push('/staff/appointments/${a.id}'),
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _StaffBottomNav(
        currentIndex: _navIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined), label: 'Appointments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded), label: 'Patients'),
        ],
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) context.push('/staff/appointments');
          if (i == 2) context.push('/staff/patients');
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    await auth.signOut();
    if (context.mounted) context.go('/login');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. SCHEDULING OFFICER DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────

/// Scheduling officer view: slot overview, department capacity, quick manage.
class SchedulingOfficerDashboardScreen extends StatefulWidget {
  const SchedulingOfficerDashboardScreen({super.key});

  @override
  State<SchedulingOfficerDashboardScreen> createState() =>
      _SchedulingOfficerDashboardScreenState();
}

class _SchedulingOfficerDashboardScreenState
    extends State<SchedulingOfficerDashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _RoleAppBar(
            title: 'Scheduling',
            subtitle: user?.fullName ?? 'Scheduling Officer',
            roleColor: AppColors.secondary,
            roleLabel: 'Slot Management',
            onSignOut: () => _signOut(context, auth),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Slot overview ─────────────────────────────────────────
                FutureBuilder<List<SlotModel>>(
                  future: context.read<DepartmentProvider>().getAllSlots(),
                  builder: (ctx, snap) {
                    final slots = snap.data ?? [];
                    final available = slots.where((s) => s.isAvailable).length;
                    final full =
                        slots.where((s) => s.isActive && !s.isAvailable).length;
                    final inactive = slots.where((s) => !s.isActive).length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Slot Overview'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatTile(
                              label: 'Total',
                              value: slots.length,
                              color: AppColors.primary,
                              icon: Icons.grid_view_rounded,
                            ),
                            _StatTile(
                              label: 'Available',
                              value: available,
                              color: AppColors.success,
                              icon: Icons.check_circle_outline,
                            ),
                            _StatTile(
                              label: 'Full',
                              value: full,
                              color: AppColors.error,
                              icon: Icons.block_rounded,
                            ),
                            _StatTile(
                              label: 'Inactive',
                              value: inactive,
                              color: AppColors.textMuted,
                              icon: Icons.pause_circle_outline,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 22),

                // ── Quick actions ─────────────────────────────────────────
                const _SectionLabel('Quick Actions'),
                const SizedBox(height: 10),
                _QuickActionGrid(actions: [
                  _QuickAction(
                    label: 'Manage\nSlots',
                    icon: Icons.edit_calendar_outlined,
                    color: AppColors.secondary,
                    onTap: () => context.push('/staff/schedules'),
                  ),
                  _QuickAction(
                    label: 'View\nAppointments',
                    icon: Icons.event_note_outlined,
                    color: AppColors.primary,
                    onTap: () => context.push('/staff/appointments'),
                  ),
                  _QuickAction(
                    label: 'Departments',
                    icon: Icons.local_hospital_outlined,
                    color: AppColors.roleReceptionist,
                    onTap: () => context.push('/patient/departments'),
                  ),
                ]),

                const SizedBox(height: 22),

                // ── Department capacity breakdown ─────────────────────────
                const _SectionLabel('Department Capacity'),
                const SizedBox(height: 10),
                StreamBuilder<List<DepartmentModel>>(
                  stream: context
                      .read<DepartmentProvider>()
                      .activeDepartmentsStream(),
                  builder: (ctx, deptSnap) {
                    final depts = deptSnap.data ?? [];
                    if (depts.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.local_hospital_outlined,
                        message: 'No active departments.',
                      );
                    }
                    return Column(
                      children: depts
                          .take(6)
                          .map((d) => _DepartmentCapacityTile(
                              departmentId: d.id, departmentName: d.name))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _StaffBottomNav(
        currentIndex: _navIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.edit_calendar_outlined), label: 'Schedules'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined), label: 'Appointments'),
        ],
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) context.push('/staff/schedules');
          if (i == 2) context.push('/staff/appointments');
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context, AuthProvider auth) async {
    await auth.signOut();
    if (context.mounted) context.go('/login');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Collapsible SliverAppBar with the MediCare logo, role colour, and sign-out.
class _RoleAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color roleColor;
  final String roleLabel;
  final VoidCallback onSignOut;

  const _RoleAppBar({
    required this.title,
    required this.subtitle,
    required this.roleColor,
    required this.roleLabel,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: roleColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [roleColor, roleColor.withValues(alpha: 0.80)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // MediCare logo — white tinted
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const AppLogoIcon(size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleLabel,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: 'Sign out',
                    onPressed: onSignOut,
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// A metric tile used in the stats row.
class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionGrid extends StatelessWidget {
  final List<_QuickAction> actions;
  const _QuickActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: actions.map((a) => _QuickActionTile(action: a)).toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: action.color.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(height: 7),
              Text(
                action.label,
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

class _AppointmentListTile extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  const _AppointmentListTile({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    Color statusColor;
    if (a.isConfirmed) {
      statusColor = AppColors.success;
    } else if (a.isPending) {
      statusColor = AppColors.warning;
    } else if (a.isCancelled) {
      statusColor = AppColors.error;
    } else {
      statusColor = AppColors.textMuted;
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAF0F8)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDF7F4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    a.patientName.isNotEmpty
                        ? a.patientName[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
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
                      a.patientName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${a.departmentName}  ·  ${a.appointmentTime}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  a.status[0].toUpperCase() + a.status.substring(1),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentCapacityTile extends StatelessWidget {
  final String departmentId;
  final String departmentName;
  const _DepartmentCapacityTile(
      {required this.departmentId, required this.departmentName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SlotModel>>(
      future: context
          .read<DepartmentProvider>()
          .getAllSlots(departmentId: departmentId),
      builder: (ctx, snap) {
        final slots = snap.data ?? [];
        final total = slots.fold<int>(0, (s, sl) => s + sl.capacity);
        final booked = slots.fold<int>(0, (s, sl) => s + sl.bookedCount);
        final pct = total > 0 ? booked / total : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    departmentName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$booked / $total',
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
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  color: pct > 0.85
                      ? AppColors.error
                      : pct > 0.60
                          ? AppColors.warning
                          : AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StaffBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;

  const _StaffBottomNav({
    required this.currentIndex,
    required this.items,
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
        items: items,
      ),
    );
  }
}
