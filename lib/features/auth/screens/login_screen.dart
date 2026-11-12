import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/biometric_service.dart';

/// MediCare login screen — matches the teal glassmorphism mockup:
///
///  • Full-screen teal gradient background with organic blob decorations
///  • MediCare heart+ECG logo + name + tagline at the top
///  • Frosted-glass white card containing the form
///  • Email field, Password field (show/hide), Remember Me, Forgot Password
///  • Sign In button (white, full-width)
///  • OR divider → Continue with Google
///  • Don't have an account? Register →
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _biometricEnabled = false;
  final _biometricService = BiometricService();

  // ── Teal design tokens (from mockup) ──────────────────────────────────────
  static const _tealPrimary = Color(0xFF008F87);
  static const _tealDark = Color(0xFF006D68);
  static const _tealLight = Color(0xFFDDF7F4);
  static const _darkText = Color(0xFF263238);

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final enabled = await _biometricService.isEnabled();
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Auth handlers ─────────────────────────────────────────────────────────

  Future<void> _handleSignIn() async {
    UiHelpers.hideKeyboard(context);
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      await _offerBiometricEnable();
      _routeByRole(auth.currentRole);
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
      await _offerBiometricEnable();
      _routeByRole(auth.currentRole);
    } else if (auth.errorMessage != null) {
      UiHelpers.showErrorSnackBar(context, auth.errorMessage!);
    }
  }

  Future<void> _handleBiometric() async {
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
      UiHelpers.showErrorSnackBar(context, 'Session expired. Please sign in normally.');
      return;
    }
    if (!mounted) return;
    _routeByRole(auth.currentRole);
  }

  Future<void> _offerBiometricEnable() async {
    if (_biometricEnabled || !await _biometricService.canUseBiometrics()) {
      return;
    }
    if (!mounted) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enable Fingerprint Login?'),
        content: const Text(
          'Use your fingerprint for faster sign-in on future visits.',
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

  void _routeByRole(UserRole role) {
    if (role.isAdmin) {
      context.go('/admin');
    } else if (role.isDoctor) {
      context.go('/doctor');
    } else if (role.isReceptionist) {
      context.go('/receptionist');
    } else if (role.isSchedulingOfficer) {
      context.go('/scheduling');
    } else if (role.isPatient) {
      context.go('/patient');
    } else {
      context.go('/account-pending');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF008F87), // primary teal
              Color(0xFF006D68), // dark teal
              Color(0xFF004D49), // deep teal
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative blobs ───────────────────────────────────────────
            _TealBlob(top: -60, right: -60, size: 220,
                color: Colors.white.withValues(alpha: 0.08)),
            _TealBlob(bottom: -80, left: -40, size: 260,
                color: Colors.white.withValues(alpha: 0.06)),
            _TealBlob(top: 180, right: -100, size: 180,
                color: Colors.white.withValues(alpha: 0.05)),

            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ── Logo ─────────────────────────────────────────────
                    _MediCareLogo(),
                    const SizedBox(height: 10),
                    const Text(
                      'MediCare',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Text(
                      'Your Health, Our Priority',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Glassmorphism card ────────────────────────────────
                    Container(
                      constraints: const BoxConstraints(maxWidth: 460),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(
                          24, 28, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            // Heading
                            const Text(
                              'Welcome Back!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sign in to manage your hospital appointments',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Error banner
                            if (auth.errorMessage != null) ...[
                              _ErrorBanner(auth.errorMessage!),
                              const SizedBox(height: 14),
                            ],

                            // Email Address
                            _GlassFieldLabel(
                              icon: Icons.email_outlined,
                              label: 'Email Address',
                            ),
                            const SizedBox(height: 6),
                            _GlassTextField(
                              controller: _emailCtrl,
                              hint: 'Enter your email address',
                              keyboardType:
                                  TextInputType.emailAddress,
                              validator: Validators.validateEmail,
                            ),

                            const SizedBox(height: 16),

                            // Password
                            _GlassFieldLabel(
                              icon: Icons.lock_outlined,
                              label: 'Password',
                            ),
                            const SizedBox(height: 6),
                            _GlassTextField(
                              controller: _passwordCtrl,
                              hint: 'Enter your password',
                              obscure: _obscurePassword,
                              validator: Validators.validatePassword,
                              onSubmit: (_) => _handleSignIn(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                                onPressed: () => setState(() =>
                                    _obscurePassword =
                                        !_obscurePassword),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Remember me + Forgot password
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        checkColor: _tealDark,
                                        fillColor:
                                            WidgetStateProperty
                                                .resolveWith((s) =>
                                                    s.contains(WidgetState
                                                        .selected)
                                                        ? Colors.white
                                                        : Colors.white
                                                            .withValues(
                                                                alpha:
                                                                    0.2)),
                                        side: const BorderSide(
                                            color: Colors.white70,
                                            width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  4),
                                        ),
                                        onChanged: (v) => setState(
                                            () => _rememberMe =
                                                v ?? false),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Remember Me',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => context
                                      .push('/forgot-password'),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      decoration:
                                          TextDecoration.underline,
                                      decorationColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Sign In button
                            _SignInButton(
                              isLoading: auth.isLoading,
                              onPressed: _handleSignIn,
                            ),

                            const SizedBox(height: 20),

                            // OR divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white
                                        .withValues(alpha: 0.4),
                                    thickness: 1,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white
                                        .withValues(alpha: 0.4),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Continue with Google
                            _GlassOutlineButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : _handleGoogle,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  _GoogleIcon(),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Fingerprint (only shown if enabled)
                            if (_biometricEnabled) ...[
                              const SizedBox(height: 10),
                              _GlassOutlineButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : _handleBiometric,
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.fingerprint_rounded,
                                        color: Colors.white,
                                        size: 24),
                                    SizedBox(width: 10),
                                    Text(
                                      'Login with Fingerprint',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 22),

                            // Register link
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account?  ",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.push('/register'),
                                  child: const Text(
                                    'Register →',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DECORATIVE BLOB
// ─────────────────────────────────────────────────────────────────────────────

class _TealBlob extends StatelessWidget {
  final double? top, bottom, left, right, size;
  final Color color;
  const _TealBlob(
      {this.top, this.bottom, this.left, this.right,
      required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEDICARE LOGO (heart + ECG + cross)
// ─────────────────────────────────────────────────────────────────────────────

class _MediCareLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(painter: _MedicareLogoPainter()),
    );
  }
}

class _MedicareLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // White heart shape
    final heartPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(w * 0.5, h * 0.85);
    path.cubicTo(w * 0.0, h * 0.5, w * 0.0, h * 0.1, w * 0.25, h * 0.18);
    path.cubicTo(w * 0.38, h * 0.22, w * 0.5, h * 0.34, w * 0.5, h * 0.38);
    path.cubicTo(w * 0.5, h * 0.34, w * 0.62, h * 0.22, w * 0.75, h * 0.18);
    path.cubicTo(w * 1.0, h * 0.1, w * 1.0, h * 0.5, w * 0.5, h * 0.85);
    path.close();
    canvas.drawPath(path, heartPaint);

    // Teal plus/cross
    final crossPaint = Paint()
      ..color = const Color(0xFF008F87)
      ..style = PaintingStyle.fill;

    final cx = w * 0.5;
    final cy = h * 0.50;
    final thick = w * 0.12;
    final len = w * 0.32;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy), width: len, height: thick),
        const Radius.circular(3),
      ),
      crossPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy), width: thick, height: len),
        const Radius.circular(3),
      ),
      crossPaint,
    );

    // Teal ECG pulse
    final pulsePaint = Paint()
      ..color = const Color(0xFF008F87).withValues(alpha: 0.6)
      ..strokeWidth = (w * 0.040).clamp(1.5, 3.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pulse = Path();
    pulse.moveTo(w * 0.12, cy);
    pulse.lineTo(w * 0.30, cy);
    pulse.lineTo(w * 0.36, cy + h * 0.08);
    pulse.lineTo(w * 0.46, cy - h * 0.18);
    pulse.lineTo(w * 0.54, cy + h * 0.18);
    pulse.lineTo(w * 0.62, cy - h * 0.06);
    pulse.lineTo(w * 0.68, cy);
    pulse.lineTo(w * 0.88, cy);
    canvas.drawPath(pulse, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _GlassFieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GlassFieldLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmit;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: validator,
      onFieldSubmitted: onSubmit,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.4), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.4), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFFCDD2), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFFCDD2), width: 2.0),
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFFCDD2),
          fontSize: 11,
        ),
      ),
    );
  }
}

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
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
          foregroundColor: const Color(0xFF006D68),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Color(0xFF008F87),
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

class _GlassOutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const _GlassOutlineButton(
      {required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
              color: Colors.white.withValues(alpha: 0.6), width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
        ),
        child: child,
      ),
    );
  }
}

/// 4-colour Google 'G' logo.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 24, height: 24, child: CustomPaint(painter: _GoogleGPainter()));
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _colors = [
    Color(0xFF4285F4),
    Color(0xFFEA4335),
    Color(0xFFFBBC05),
    Color(0xFF34A853),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.22
      ..strokeCap = StrokeCap.butt;

    for (var i = 0; i < 4; i++) {
      paint.color = _colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.6),
        (3.14159 / 2) + i * (3.14159 * 2 / 4),
        3.14159 * 2 / 4 - 0.12,
        false,
        paint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - s.width * 0.11, r * 0.62, s.width * 0.22),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCDD2).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFFFCDD2).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFFCDD2), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFFFCDD2),
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
