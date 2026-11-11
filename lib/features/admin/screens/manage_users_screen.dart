import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user_model.dart';
import '../../../services/user_service.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Screen 19: Manage Users — searchable list with role filter, account
/// status toggle, and role reassignment.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _role = 'all';

  static const _roleFilters = [
    ('all', 'All'),
    (AppConstants.rolePatient, 'Patients'),
    (AppConstants.roleStaff, 'Staff'),
    (AppConstants.roleReceptionist, 'Receptionists'),
    (AppConstants.roleDoctor, 'Doctors'),
    (AppConstants.roleSchedulingOfficer, 'Scheduling'),
    (AppConstants.roleAdmin, 'Admins'),
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
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────────────────
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
                    setState(() => _search = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search by name or email...',
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

          // ── Role Filter Chips ─────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _roleFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (value, label) = _roleFilters[i];
                  final selected = _role == value;
                  return FilterChip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() => _role = value),
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

          // ── Users List ────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: UserService().usersStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = (snap.data ?? []).where((u) {
                  final matchesSearch = _search.isEmpty ||
                      u.fullName.toLowerCase().contains(_search) ||
                      u.email.toLowerCase().contains(_search);
                  final matchesRole = _role == 'all' || u.role == _role;
                  return matchesSearch && matchesRole;
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(BootstrapIcons.people,
                            size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          _search.isNotEmpty
                              ? 'No results for "$_search"'
                              : 'No users found',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _UserTile(user: users[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

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
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: _roleColor(user.role).withValues(alpha: 0.15),
          child: Text(
            user.fullName.isNotEmpty
                ? user.fullName[0].toUpperCase()
                : user.email.isNotEmpty
                    ? user.email[0].toUpperCase()
                    : '?',
            style: TextStyle(
              color: _roleColor(user.role),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : user.email,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(user.email,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                _RoleBadge(role: user.role),
                const SizedBox(width: 6),
                _StatusBadge(isActive: user.isActive),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(BootstrapIcons.three_dots_vertical,
              color: AppColors.textMuted),
          onPressed: () => _showOptions(context, user),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return AppColors.roleAdmin;
      case AppConstants.roleDoctor:
        return AppColors.roleDoctor;
      case AppConstants.roleStaff:
      case AppConstants.roleReceptionist:
        return AppColors.roleStaff;
      default:
        return AppColors.rolePatient;
    }
  }

  void _showOptions(BuildContext context, UserModel user) {
    final userService = UserService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName.isNotEmpty ? user.fullName : user.email,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            _RoleBadge(role: user.role),
            const SizedBox(height: 16),
            const Divider(),

            // Toggle active
            ListTile(
              leading: Icon(
                user.isActive
                    ? BootstrapIcons.slash_circle
                    : BootstrapIcons.check_circle,
                color: user.isActive ? AppColors.error : AppColors.success,
              ),
              title: Text(
                user.isActive ? 'Deactivate Account' : 'Activate Account',
                style: TextStyle(
                  color: user.isActive ? AppColors.error : AppColors.success,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await userService.setUserActive(user.uid,
                    active: !user.isActive);
              },
            ),

            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Change Role',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 12)),
              ),
            ),

            for (final role in [
              AppConstants.rolePatient,
              AppConstants.roleReceptionist,
              AppConstants.roleDoctor,
              AppConstants.roleSchedulingOfficer,
              AppConstants.roleAdmin,
            ])
              if (role != user.role)
                ListTile(
                  dense: true,
                  leading: const Icon(BootstrapIcons.arrow_left_right,
                      color: AppColors.primary),
                  title: Text(
                      'Set as ${role[0].toUpperCase()}${role.substring(1)}'),
                  onTap: () async {
                    Navigator.pop(context);
                    await userService.updateUserRole(user.uid, role);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (role) {
      case AppConstants.roleAdmin:
        bg = AppColors.roleAdminBg;
        fg = AppColors.roleAdmin;
        break;
      case AppConstants.roleDoctor:
        bg = AppColors.roleDoctorBg;
        fg = AppColors.roleDoctor;
        break;
      case AppConstants.roleStaff:
      case AppConstants.roleReceptionist:
        bg = AppColors.roleStaffBg;
        fg = AppColors.roleStaff;
        break;
      default:
        bg = AppColors.rolePatientBg;
        fg = AppColors.rolePatient;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(role,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.statusConfirmed : AppColors.statusCancelled,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive
              ? AppColors.statusConfirmedText
              : AppColors.statusCancelledText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
