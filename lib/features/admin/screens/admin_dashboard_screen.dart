import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Screen 18: Admin Dashboard — stats overview with navigation to all admin tools.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<Map<String, int>> _loadCounts() async {
    final db = FirebaseFirestore.instance;
    Future<int> count(Query<Map<String, dynamic>> query) async =>
        (await query.count().get()).count ?? 0;

    final results = await Future.wait<int>([
      count(db.collection('users').where('role', isEqualTo: 'patient')),
      count(db.collection('users').where(
        'role',
        whereIn: ['doctor', 'receptionist', 'scheduling_officer'],
      )),
      count(db.collection('departments')),
      count(db.collection('appointments')),
      count(
          db.collection('appointments').where('status', isEqualTo: 'pending')),
      count(db
          .collection('appointments')
          .where('status', isEqualTo: 'completed')),
    ]);
    return {
      'patients': results[0],
      'staff': results[1],
      'departments': results[2],
      'appointments': results[3],
      'pending': results[4],
      'completed': results[5],
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ─────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF008F87), Color(0xFF006D68)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            user?.fullName ?? 'Administrator',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(BootstrapIcons.box_arrow_right,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats Grid ─────────────────────────────────────────────
                  FutureBuilder<Map<String, int>>(
                    future: _loadCounts(),
                    builder: (ctx, snap) {
                      if (snap.hasError) {
                        return const Text(
                          'Unable to load system overview.',
                          style: TextStyle(color: AppColors.error),
                        );
                      }
                      if (!snap.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final counts = snap.data!;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: [
                          _AdminStatCard(
                            icon: BootstrapIcons.people_fill,
                            title: 'Total Patients',
                            count: '${counts['patients']}',
                            color: AppColors.primary,
                          ),
                          _AdminStatCard(
                            icon: BootstrapIcons.person_badge,
                            title: 'Staff',
                            count: '${counts['staff']}',
                            color: const Color(0xFF7C3AED),
                          ),
                          _AdminStatCard(
                            icon: BootstrapIcons.hospital,
                            title: 'Departments',
                            count: '${counts['departments']}',
                            color: const Color(0xFF00B4A8),
                          ),
                          _AdminStatCard(
                            icon: BootstrapIcons.calendar_fill,
                            title: 'Appointments',
                            count: '${counts['appointments']}',
                            color: AppColors.success,
                          ),
                          _AdminStatCard(
                            icon: BootstrapIcons.clock,
                            title: 'Pending',
                            count: '${counts['pending']}',
                            color: const Color(0xFFD97706),
                          ),
                          _AdminStatCard(
                            icon: BootstrapIcons.check_circle,
                            title: 'Completed',
                            count: '${counts['completed']}',
                            color: const Color(0xFF059669),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Admin Menu Card ────────────────────────────────────────
                  const Text(
                    'Administration',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: const Color(0xFFE9F0FA), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _AdminMenuTile(
                          icon: BootstrapIcons.people,
                          title: 'User Management',
                          subtitle: 'Accounts, roles, and permissions',
                          isFirst: true,
                          onTap: () => context.push('/admin/users'),
                        ),
                        const Divider(height: 1, indent: 58),
                        _AdminMenuTile(
                          icon: BootstrapIcons.hospital,
                          title: 'Department Management',
                          subtitle: 'Add, edit, activate departments',
                          onTap: () => context.push('/admin/departments'),
                        ),
                        const Divider(height: 1, indent: 58),
                        _AdminMenuTile(
                          icon: BootstrapIcons.bar_chart,
                          title: 'Reports',
                          subtitle: 'Appointment summaries by date/dept',
                          onTap: () => context.push('/admin/reports'),
                        ),
                        const Divider(height: 1, indent: 58),
                        _AdminMenuTile(
                          icon: BootstrapIcons.clipboard,
                          title: 'Audit Logs',
                          subtitle: 'Administrative action history',
                          isLast: true,
                          onTap: () => context.push('/admin/audit'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _adminBottomNav(context),
    );
  }

  Widget _adminBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAF0F8), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1:
              context.push('/admin/users');
              break;
            case 2:
              context.push('/admin/departments');
              break;
            case 3:
              context.push('/admin/reports');
              break;
          }
        },
        elevation: 0,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.house_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.hospital),
            label: 'Departments',
          ),
          BottomNavigationBarItem(
            icon: Icon(BootstrapIcons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String count;
  final Color color;

  const _AdminStatCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _AdminMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(18) : Radius.zero,
        bottom: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
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
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
