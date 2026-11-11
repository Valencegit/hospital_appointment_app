import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/biometric_service.dart';

/// MediCare Login Screen — Unified Teal Theme
/// Features:
///  • Teal gradient hero with MediCare branding
///  • Email / Password with password visibility toggle
///  • Remember Me checkbox
///  • Forgot Password link → Firebase reset
///  • Sign In button (email/password Firebase auth)
///  • OR divider
///  • Continue with Google (Firebase Google Sign-In)
///  • Don't have an account? Register link
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _biometricEnabled = false;
  bool _rememberMe = false;
  final _biometricService = BiometricService();

  // MediCare Teal Design Tokens
  static const _primaryTeal = Color(0xFF008F87);
  static const _darkTeal = Color(0xFF006D68);
  static const _lightTeal = Color(0xFFDDF7F4);
  static const _textDark = Color(0xFF263238);
  static const _textMid = Color(0xFF546E7A);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    _loadBiometricState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _rememberMe = prefs.getBool(AppConstants.prefKeyRememberMe) ?? false;
        if (_rememberMe) {
          _emailCtrl.text = prefs.getString(AppConstants.prefKeySavedEmail) ?? '';
        }
      });
    } catch (e) {
      debugPrint('[LoginScreen] Could not load remembered email: $e');
    }
  }

  Future<void> _loadBiometricState() async {
    final enabled = await _biometricService.isEnabled();
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefKeyRememberMe, _rememberMe);
      if (_rememberMe) {
        await prefs.setString(AppConstants.prefKeySavedEmail, _emailCtrl.text.trim());
      } else {
        await prefs.remove(AppConstants.prefKeySavedEmail);
      }
    } catch (e) {
      debugPrint('[LoginScreen] Could not save remembered email: $e');
    }
  }

  Future<void> _handleLogin() async {
    UiHelpers.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      await _saveRememberedEmail();
      await _offerBiometricEnable();
      _routeByRole(auth.currentRole);
    } else {
      UiHelpers.showErrorSnackBar(
          context, auth.errorMessage ?? AppConstants.errAuthFailed);
    }
  }

  Future<void> _handleGoogle() async {
    UiHelpers.hideKeyboard(context);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      await _offerBiometricEnable();
      _routeByRole(auth.currentRole);
    } else if (auth.errorMessage != null) {
      UiHelpers.showErrorSnackBar(context, auth.errorMessage!);
    }
  }

  Future<void> _offerBiometricEnable() async {
    if (_biometricEnabled || !await _biometricService.canUseBiometrics()) return;
    if (!mounted) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enable Fingerprint Login?'),
        content: const Text(
          'Use your fingerprint for faster access on future visits.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enable')),
        ],
      ),
    );
    if (enable == true && await _biometricService.enable()) {
      if (!mounted) return;
      setState(() => _biometricEnabled = true);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final auth = context.read<AuthProvider>();
    if (!await _biometricService.authenticate()) {
      if (!mounted) return;
      UiHelpers.showErrorSnackBar(context, 'Fingerprint authentication failed.');
      return;
    }
    if (firebase_auth.FirebaseAuth.instance.currentUser == null) {
      await _biometricService.disable();
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      UiHelpers.showErrorSnackBar(
          context, 'Session expired. Please sign in normally.');
      return;
    }
    if (!mounted) return;
    _routeByRole(auth.currentRole);
  }

  void _routeByRole(UserRole role) {
    context.go(AppRouter.dashboardForRole(role));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _lightTeal,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // ── Teal gradient hero ─────────────────────────────────────────
            _TealHeroHeader(),

            // ── Login card ────────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _LoginCard(
                      formKey: _formKey,
                      emailCtrl: _emailCtrl,
                      passwordCtrl: _passwordCtrl,
                      obscurePassword: _obscurePassword,
                      rememberMe: _rememberMe,
                      biometricEnabled: _biometricEnabled,
                      isLoading: auth.isLoading,
                      errorMessage: auth.errorMessage,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onRememberMeChanged: (val) =>
                          setState(() => _rememberMe = val ?? false),
                      onForgotPassword: () => context.push('/forgot-password'),
                      onSignIn: _handleLogin,
                      onGoogle: _handleGoogle,
                      onBiometric: _biometricEnabled ? _handleBiometricLogin : null,
                      onRegister: () => context.push('/register'),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO HEADER — Teal gradient with MediCare branding
// ─────────────────────────────────────────────────────────────────────────────

class _TealHeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 300 + topPad,
      width: double.infinity,
      child: Stack(
        children: [
          // Teal gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00CFC0),
                    Color(0xFF008F87),
                    Color(0xFF006D68),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),

          // Cross decorations
          Positioned(
            top: topPad + 24,
            left: 24,
            child: _CrossDecoration(size: 28, opacity: 0.35),
          ),
          Positioned(
            top: topPad + 50,
            right: 32,
            child: _CrossDecoration(size: 22, opacity: 0.25),
          ),

          // Central MediCare branding
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: topPad + 8),
                // Heart + ECG logo
                _MediCareLogoIcon(size: 72),
                const SizedBox(height: 14),
                const Text(
                  'MediCare',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Your Health, Our Priority',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // White wave at bottom so card slides under it
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 70,
            child: CustomPaint(painter: _TealWavePainter()),
          ),
        ],
      ),
    );
  }
}

class _CrossDecoration extends StatelessWidget {
  final double size;
  final double opacity;
  const _CrossDecoration({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _CrossPainter()),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _MediCareLogoIcon extends StatelessWidget {
  final double size;
  const _MediCareLogoIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MediCareLogoPainter()),
    );
  }
}

class _MediCareLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Heart shape
    final heartPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(w * 0.5, h * 0.78);
    path.cubicTo(w * 0.1, h * 0.55, 0, h * 0.35, w * 0.08, h * 0.22);
    path.cubicTo(w * 0.14, h * 0.1, w * 0.3, h * 0.08, w * 0.5, h * 0.26);
    path.cubicTo(w * 0.7, h * 0.08, w * 0.86, h * 0.1, w * 0.92, h * 0.22);
    path.cubicTo(w, h * 0.35, w * 0.9, h * 0.55, w * 0.5, h * 0.78);
    canvas.drawPath(path, heartPaint);

    // ECG line on heart
    final ecgPaint = Paint()
      ..color = const Color(0xFF008F87)
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final ecgPath = Path();
    ecgPath.moveTo(w * 0.12, h * 0.48);
    ecgPath.lineTo(w * 0.28, h * 0.48);
    ecgPath.lineTo(w * 0.36, h * 0.28);
    ecgPath.lineTo(w * 0.44, h * 0.62);
    ecgPath.lineTo(w * 0.52, h * 0.38);
    ecgPath.lineTo(w * 0.58, h * 0.52);
    ecgPath.lineTo(w * 0.88, h * 0.52);
    canvas.drawPath(ecgPath, ecgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _TealWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = const Color(0xFFDDF7F4);
    final path = Path()
      ..moveTo(0, h * 0.5)
      ..quadraticBezierTo(w * 0.25, 0, w * 0.5, h * 0.38)
      ..quadraticBezierTo(w * 0.75, h * 0.72, w, h * 0.22)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN CARD
// ─────────────────────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final bool rememberMe;
  final bool biometricEnabled;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignIn;
  final VoidCallback onGoogle;
  final VoidCallback? onBiometric;
  final VoidCallback onRegister;

  const _LoginCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.rememberMe,
    required this.biometricEnabled,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
    required this.onSignIn,
    required this.onGoogle,
    required this.onBiometric,
    required this.onRegister,
  });

  static const _primaryTeal = Color(0xFF008F87);
  static const _darkTeal = Color(0xFF006D68);
  static const _textDark = Color(0xFF263238);
  static const _textMid = Color(0xFF546E7A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008F87).withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Heading ──────────────────────────────────────────────────
            const Text(
              'Welcome Back!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _darkTeal,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to manage your hospital appointments',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _textMid,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // ── Error banner ──────────────────────────────────────────────
            if (errorMessage != null) ...[
              _ErrorBanner(message: errorMessage!),
              const SizedBox(height: 16),
            ],

            // ── Email field ───────────────────────────────────────────────
            _TealTextField(
              controller: emailCtrl,
              hintText: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),

            // ── Password field ────────────────────────────────────────────
            _TealTextField(
              controller: passwordCtrl,
              hintText: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              validator: Validators.validatePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF90A4AE),
                  size: 22,
                ),
                onPressed: onTogglePassword,
              ),
            ),
            const SizedBox(height: 10),

            // ── Remember Me + Forgot Password ─────────────────────────────
            Row(
              children: [
                SizedBox(
                  height: 36,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: rememberMe,
                          onChanged: isLoading ? null : onRememberMeChanged,
                          activeColor: _primaryTeal,
                          side: const BorderSide(color: _primaryTeal, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember Me',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Sign In button ────────────────────────────────────────────
            _SignInButton(isLoading: isLoading, onPressed: onSignIn),
            const SizedBox(height: 20),

            // ── OR divider ────────────────────────────────────────────────
            const _OrDivider(),
            const SizedBox(height: 16),

            // ── Continue with Google ──────────────────────────────────────
            _GoogleButton(
              onPressed: isLoading ? null : onGoogle,
            ),
            const SizedBox(height: 10),

            // ── Fingerprint (only if biometric enrolled) ──────────────────
            if (biometricEnabled) ...[
              _SocialButton(
                onPressed: isLoading ? null : onBiometric,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fingerprint_rounded,
                        size: 24, color: _primaryTeal),
                    const SizedBox(width: 10),
                    Text(
                      'Login with Fingerprint',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onBiometric != null ? _textDark : const Color(0xFFB0BEC5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 14),

            // ── Register link ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?  ",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _textMid,
                  ),
                ),
                GestureDetector(
                  onTap: onRegister,
                  child: const Text(
                    'Register →',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEAL TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _TealTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _TealTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Color(0xFF263238),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF90A4AE),
        ),
        prefixIcon: Container(
          width: 50,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF008F87),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(13),
              bottomLeft: Radius.circular(13),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 54, minHeight: 54),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF0FAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCCEEEB), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF008F87), width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2.0),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGN IN BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _SignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006D68),
          disabledBackgroundColor: const Color(0xFF006D68).withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF263238),
          side: const BorderSide(color: Color(0xFFCCEEEB), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(painter: _GoogleGPainter()),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF263238),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const _SocialButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF263238),
          side: const BorderSide(color: Color(0xFFCCEEEB), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}

/// Multicolour Google 'G' icon
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    const colors = [
      Color(0xFF4285F4),
      Color(0xFFEA4335),
      Color(0xFFFBBC05),
      Color(0xFF34A853),
    ];

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < 4; i++) {
      segmentPaint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.6),
        (3.14159 / 2) + i * (3.14159 * 2 / 4),
        3.14159 * 2 / 4 - 0.12,
        false,
        segmentPaint,
      );
    }

    // White bar for the 'G' notch
    final barPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - size.width * 0.11, r * 0.62, size.width * 0.22),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// OR DIVIDER
// ─────────────────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFCCEEEB), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF90A4AE),
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFCCEEEB), thickness: 1)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFE53935), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFE53935),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
