import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../providers/auth_provider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Metro Health Patient Profile Screen matching Mockup Screen 10.
class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  void _showChangePasswordDialog() {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Change Password',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: passwordCtrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              UiHelpers.showSuccessSnackBar(context, 'Password updated successfully.');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Help & Support',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Metro Health Hospital Support Team', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('📞 Hotline: +1 (800) 555-METRO'),
            SizedBox(height: 4),
            Text('✉️ Email: support@metrohealth.com'),
            SizedBox(height: 4),
            Text('🕒 Hours: 24/7 Patient Emergency Care'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    bool emailAlerts = true;
    bool pushAlerts = true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification Preferences',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Appointment reminders & updates'),
                value: pushAlerts,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setModalState(() => pushAlerts = val),
              ),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Booking receipts & summaries'),
                value: emailAlerts,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setModalState(() => emailAlerts = val),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    UiHelpers.showSuccessSnackBar(context, 'Notification preferences saved.');
                  },
                  child: const Text('Save Preferences'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final patient = auth.patientProfile;

    final displayName = patient?.fullName ?? user?.fullName ?? 'Sarah Johnson';
    final patientId =
        patient?.patientId ?? user?.uid.substring(0, 6).toUpperCase() ?? 'P00123';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(BootstrapIcons.arrow_left, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(BootstrapIcons.gear, color: Colors.white),
            onPressed: _showNotificationSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ── Profile Photo & Details ─────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFDDF7F4),
                        border: Border.all(color: const Color(0xFFD6E6FF), width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0] : 'S',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Patient #$patientId',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Profile Info Card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: BootstrapIcons.person_badge,
                      label: 'Patient Number',
                      value: 'P#$patientId',
                    ),
                    const Divider(height: 18, color: AppColors.divider),
                    _InfoRow(
                      icon: BootstrapIcons.person,
                      label: 'Full Name',
                      value: displayName,
                    ),
                    const Divider(height: 18, color: AppColors.divider),
                    _InfoRow(
                      icon: BootstrapIcons.envelope,
                      label: 'Email',
                      value: user?.email ?? '—',
                    ),
                    const Divider(height: 18, color: AppColors.divider),
                    _InfoRow(
                      icon: BootstrapIcons.telephone,
                      label: 'Phone',
                      value: patient?.phoneNumber ?? user?.phoneNumber ?? '—',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Settings Menu Items ─────────────────────────────────────────
              _ProfileMenuItem(
                icon: BootstrapIcons.pencil,
                title: 'Update Profile',
                onTap: () {
                  UiHelpers.showSuccessSnackBar(context, 'Profile is up to date.');
                },
              ),
              const Divider(height: 1, indent: 44, color: Color(0xFFF1F5F9)),
              _ProfileMenuItem(
                icon: BootstrapIcons.lock,
                title: 'Change Password',
                onTap: _showChangePasswordDialog,
              ),
              const Divider(height: 1, indent: 44, color: Color(0xFFF1F5F9)),
              _ProfileMenuItem(
                icon: BootstrapIcons.bell,
                title: 'Notification Settings',
                onTap: _showNotificationSettings,
              ),
              const Divider(height: 1, indent: 44, color: Color(0xFFF1F5F9)),
              _ProfileMenuItem(
                icon: BootstrapIcons.question_circle,
                title: 'Help & Support',
                onTap: _showHelpSupportDialog,
              ),

              const SizedBox(height: 36),

              // ── Logout Button ───────────────────────────────────────────────
              Center(
                child: SizedBox(
                  width: 140,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          BootstrapIcons.box_arrow_right,
                          color: AppColors.error,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF475569), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
