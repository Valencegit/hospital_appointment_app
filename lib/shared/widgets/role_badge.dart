import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/enums/user_role.dart';
/// Pill-style badge highlighting a user's role with role-specific colors and icons.
class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool isCompact;

  const RoleBadge({
    super.key,
    required this.role,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (role) {
      case UserRole.patient:
        bg = AppColors.rolePatientBg;
        fg = AppColors.rolePatient;
        break;
      case UserRole.doctor:
        bg = AppColors.roleDoctorBg;
        fg = AppColors.roleDoctor;
        break;
      case UserRole.staff:
        bg = AppColors.roleStaffBg;
        fg = AppColors.roleStaff;
        break;
      case UserRole.receptionist:
        bg = AppColors.roleReceptionistBg;
        fg = AppColors.roleReceptionist;
        break;
      case UserRole.admin:
        bg = AppColors.roleAdminBg;
        fg = AppColors.roleAdmin;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: isCompact ? 13 : 16, color: fg),
          const SizedBox(width: 5),
          Text(
            role.displayName,
            style: TextStyle(
              color: fg,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
