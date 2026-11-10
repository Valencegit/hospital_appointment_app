import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/metro_decorations.dart';
import '../widgets/social_sign_in_button.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();

  // Default to Patient; Admin tab is hidden from public UI (created via
  // the createAdminUser Cloud Function with a server-side secret)
  UserRole _selectedRole = UserRole.patient;

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl, _emailCtrl, _phoneCtrl,
      _passwordCtrl, _confirmCtrl, _departmentCtrl, _licenseCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleRegister() async {
    UiHelpers.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _fullNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      role: _selectedRole,
      department: _departmentCtrl.text.trim().isEmpty
          ? null
          : _departmentCtrl.text.trim(),
      licenseNumber: _licenseCtrl.text.trim().isEmpty
          ? null
          : _licenseCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      UiHelpers.showSuccessSnackBar(
          context, 'Account created! Welcome to ${AppConstants.appName}.');
      context.go(_selectedRole.isStaff ? '/staff' : '/patient');
    } else {
      UiHelpers.showErrorSnackBar(
          context, auth.errorMessage ?? AppConstants.errAuthFailed);
    }
  }

  Future<void> _handleGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.go(auth.currentRole.isStaff ? '/staff' : '/patient');
    } else {
      UiHelpers.showErrorSnackBar(
          context, auth.errorMessage ?? AppConstants.errAuthFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned(
            top: 0, left: 0, right: 0,
            child: MetroTopWave(height: 120),
          ),
          const Positioned(
            bottom: 0, left: 0, right: 0,
            child: MetroBottomWave(height: 80),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // ── Back button + Logo ───────────────────────────
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(BootstrapIcons.arrow_left,
                                  size: 18),
                              onPressed: () => context.pop(),
                            ),
                            const Spacer(),
                            const AppLogo(size: 36, showShadow: false),
                            const Spacer(),
                            const SizedBox(width: 40),
                          ],
                        ),

                        // ── Hospital name ────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Metro Health',
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Hospital Appointment System',
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Header ───────────────────────────────────────
                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join our healthcare community',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunitoSans(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),

                        // ── Error banner ─────────────────────────────────
                        if (auth.errorMessage != null) ...[
                          _ErrorBanner(message: auth.errorMessage!),
                          const SizedBox(height: 14),
                        ],

                        // ── Role selector tabs ───────────────────────────
                        _RoleTabs(
                          selected: _selectedRole,
                          onChanged: (r) => setState(() => _selectedRole = r),
                        ),
                        const SizedBox(height: 20),

                        // ── Full name ────────────────────────────────────
                        CustomTextField(
                          controller: _fullNameCtrl,
                          label: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: BootstrapIcons.person,
                          validator: Validators.validateName,
                        ),
                        const SizedBox(height: 14),

                        // ── Email ────────────────────────────────────────
                        CustomTextField(
                          controller: _emailCtrl,
                          label: 'Email Address',
                          hintText: 'Enter your email address',
                          prefixIcon: BootstrapIcons.envelope,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 14),

                        // ── Phone ────────────────────────────────────────
                        CustomTextField(
                          controller: _phoneCtrl,
                          label: 'Phone Number',
                          hintText: 'Enter your phone number',
                          prefixIcon: BootstrapIcons.telephone,
                          keyboardType: TextInputType.phone,
                          validator: Validators.validatePhone,
                        ),
                        const SizedBox(height: 14),

                        // ── Staff-only extra fields ──────────────────────
                        if (_selectedRole.isStaff) ...[
                          CustomTextField(
                            controller: _departmentCtrl,
                            label: 'Department',
                            hintText: 'e.g. Cardiology, Pediatrics',
                            prefixIcon: BootstrapIcons.building,
                            validator: (v) =>
                                Validators.validateRequired(v, 'Department'),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _licenseCtrl,
                            label: 'Medical License Number',
                            hintText: 'e.g. LIC-2026-9921',
                            prefixIcon: BootstrapIcons.shield_check,
                            validator: (v) => Validators.validateRequired(
                                v, 'License number'),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Password ─────────────────────────────────────
                        CustomTextField(
                          controller: _passwordCtrl,
                          label: 'Password',
                          hintText: 'Create a password',
                          prefixIcon: BootstrapIcons.lock,
                          isPassword: true,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 14),

                        // ── Confirm password ─────────────────────────────
                        CustomTextField(
                          controller: _confirmCtrl,
                          label: 'Confirm Password',
                          hintText: 'Re-enter your password',
                          prefixIcon: BootstrapIcons.lock,
                          isPassword: true,
                          validator: (v) => Validators.validateConfirmPassword(
                              v, _passwordCtrl.text),
                          onFieldSubmitted: (_) => _handleRegister(),
                        ),
                        const SizedBox(height: 22),

                        // ── Create Account button ────────────────────────
                        CustomButton(
                          text: 'Create Account',
                          icon: BootstrapIcons.person_add,
                          isLoading: auth.isLoading,
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: 20),

                        // ── OR divider ───────────────────────────────────
                        const _OrDivider(),
                        const SizedBox(height: 16),

                        // ── Social sign-up ───────────────────────────────
                        SocialSignInButton(
                          label: 'Sign up with Google',
                          assetPath: 'assets/icons/google_logo.png',
                          onPressed: auth.isLoading ? null : _handleGoogle,
                        ),
                        const SizedBox(height: 10),
                        const SocialSignInButton(
                          label: 'Sign up with Apple',
                          icon: BootstrapIcons.apple,
                          onPressed: null,
                          isDisabled: true,
                        ),
                        const SizedBox(height: 10),
                        const SocialSignInButton(
                          label: 'Sign up with Phone',
                          icon: BootstrapIcons.phone,
                          onPressed: null,
                          isDisabled: true,
                        ),
                        const SizedBox(height: 24),

                        // ── Login link ───────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role tabs ──────────────────────────────────────────────────────────────

class _RoleTabs extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  // Patient and Staff only — Admin accounts are created via Cloud Function
  static const _tabs = [
    (UserRole.patient, BootstrapIcons.person, 'Patient'),
    (UserRole.staff, BootstrapIcons.person_badge, 'Staff'),
    (UserRole.admin, BootstrapIcons.shield_lock, 'Admin'),
  ];

  const _RoleTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final (role, icon, label) = tab;
          final isSelected = selected == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(BootstrapIcons.exclamation_circle, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
