import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/custom_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_input.dart';
import '../widgets/social_sign_in_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _darkTeal = Color(0xFF006D68);
  static const _primary = Color(0xFF008F87);
  static const _background = Color(0xFFDDF7F4);

  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 18, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Select date of birth',
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
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
      role: UserRole.patient,
      dateOfBirth: _dateOfBirth,
      gender: _gender,
    );

    if (!mounted) return;
    if (ok) {
      UiHelpers.showSuccessSnackBar(
        context,
        'Account created! Welcome to ${AppConstants.appName}.',
      );
      context.go(AppRouter.dashboardForRole(auth.currentRole));
    } else {
      UiHelpers.showErrorSnackBar(
        context,
        auth.errorMessage ?? AppConstants.errAuthFailed,
      );
    }
  }

  Future<void> _handleGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      context.go(AppRouter.dashboardForRole(auth.currentRole));
    } else {
      UiHelpers.showErrorSnackBar(
        context,
        auth.errorMessage ?? AppConstants.errAuthFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Back to login',
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: _darkTeal,
                        ),
                      ),
                      const AppLogo(size: 56, showShadow: true),
                      const SizedBox(height: 8),
                      const Text(
                        'MediCare',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _darkTeal,
                        ),
                      ),
                      const Text(
                        'Hospital Appointment System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Create Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _darkTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Join MediCare for better healthcare services',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFF607D95),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (auth.errorMessage != null) ...[
                        _ErrorBanner(message: auth.errorMessage!),
                        const SizedBox(height: 14),
                      ],
                      GlassInput(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline_rounded,
                        controller: _fullNameCtrl,
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 12),
                      GlassInput(
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 12),
                      GlassInput(
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        icon: Icons.phone_outlined,
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),
                      const SizedBox(height: 12),
                      _PatientDateField(
                        date: _dateOfBirth,
                        onTap: _selectDateOfBirth,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender (optional)',
                          prefixIcon: Icon(Icons.wc_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'Non-binary',
                            child: Text('Non-binary'),
                          ),
                          DropdownMenuItem(
                            value: 'Prefer not to say',
                            child: Text('Prefer not to say'),
                          ),
                        ],
                        onChanged: auth.isLoading
                            ? null
                            : (value) => setState(() => _gender = value),
                      ),
                      const SizedBox(height: 12),
                      GlassInput(
                        label: 'Password',
                        hint: 'Create a password',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordCtrl,
                        obscureText: true,
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 12),
                      GlassInput(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outline_rounded,
                        controller: _confirmCtrl,
                        obscureText: true,
                        validator: (value) =>
                            Validators.validateConfirmPassword(
                          value,
                          _passwordCtrl.text,
                        ),
                      ),
                      const SizedBox(height: 18),
                      CustomButton(
                        text: 'Create Account',
                        icon: Icons.person_add_alt_1_rounded,
                        isLoading: auth.isLoading,
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: 16),
                      const _OrDivider(),
                      const SizedBox(height: 14),
                      SocialSignInButton(
                        label: 'Continue with Google',
                        assetPath: 'assets/icons/google_logo.png',
                        onPressed: auth.isLoading ? null : _handleGoogle,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Public registration creates patient accounts only. '
                        'Staff accounts are created by an administrator.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF607D95),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF607D95),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text(
                              'Login Here',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PatientDateField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _PatientDateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formattedDate = date == null
        ? 'Select your date of birth (optional)'
        : '${date!.day.toString().padLeft(2, '0')}/'
            '${date!.month.toString().padLeft(2, '0')}/${date!.year}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: Icon(Icons.cake_outlined),
          border: OutlineInputBorder(),
        ),
        child: Text(
          formattedDate,
          style: TextStyle(
            color: date == null
                ? const Color(0xFF90A4AE)
                : _RegisterScreenState._darkTeal,
          ),
        ),
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
        Expanded(child: Divider(color: Color(0xFFD6E2F0))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF90A4B8),
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFD6E2F0))),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
