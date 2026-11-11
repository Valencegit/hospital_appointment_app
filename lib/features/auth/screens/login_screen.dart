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

/// Login screen matching the MediCare mockup:
/// • Hospital building hero + blue wave header
/// • MediCare heart+ECG logo with tagline
/// • White card with "Welcome Back!" heading
/// • Email / Password fields (label above, icon inside)
/// • Sign In button → OR → Google → Fingerprint
/// • Register link + Secure & Trusted footer
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
  bool _biometricEnabled = false;
  bool _rememberMe = false;
  final _biometricService = BiometricService();

  // Design tokens matching the mockup
  static const _primary = Color(0xFF1266C5);
  static const _darkNavy = Color(0xFF183B5B);
  static const _lightBlue = Color(0xFFF1F6FC);

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _rememberMe =
            preferences.getBool(AppConstants.prefKeyRememberMe) ?? false;
        if (_rememberMe) {
          _emailCtrl.text =
              preferences.getString(AppConstants.prefKeySavedEmail) ?? '';
        }
      });
    } catch (error) {
      debugPrint('[LoginScreen] Could not load remembered email: $error');
    }
  }

  Future<void> _loadBiometricState() async {
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

  Future<void> _saveRememberedEmail() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(AppConstants.prefKeyRememberMe, _rememberMe);
      if (_rememberMe) {
        await preferences.setString(
          AppConstants.prefKeySavedEmail,
          _emailCtrl.text.trim(),
        );
      } else {
        await preferences.remove(AppConstants.prefKeySavedEmail);
      }
    } catch (error) {
      debugPrint('[LoginScreen] Could not save remembered email: $error');
    }
  }

  Future<void> _handleGoogle() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      await _offerBiometricEnable();
      _routeByRole(auth.currentRole);
    } else {
      UiHelpers.showErrorSnackBar(
          context, auth.errorMessage ?? AppConstants.errAuthFailed);
    }
  }

  Future<void> _offerBiometricEnable() async {
    if (_biometricEnabled || !await _biometricService.canUseBiometrics()) {
      return;
    }
    if (!mounted) {
      return;
    }
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
      UiHelpers.showErrorSnackBar(
          context, 'Fingerprint authentication failed.');
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
      backgroundColor: _lightBlue,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // ── Hospital hero header ────────────────────────────────────────
            _HospitalHeroHeader(),

            // ── White login card ────────────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 460),
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _darkNavy.withValues(alpha: 0.10),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome heading
                        const Text(
                          'Welcome Back!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _darkNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in to manage your hospital appointments',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF607D95),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error banner
                        if (auth.errorMessage != null) ...[
                          _ErrorBanner(message: auth.errorMessage!),
                          const SizedBox(height: 16),
                        ],

                        // Email Address field
                        const _FieldLabel(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                        ),
                        const SizedBox(height: 6),
                        _LoginTextField(
                          controller: _emailCtrl,
                          hintText: 'Enter your email address',
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 18),

                        // Password field
                        const _FieldLabel(
                          icon: Icons.lock_outlined,
                          label: 'Password',
                        ),
                        const SizedBox(height: 6),
                        _LoginTextField(
                          controller: _passwordCtrl,
                          hintText: 'Enter your password',
                          obscureText: _obscurePassword,
                          validator: Validators.validatePassword,
                          onFieldSubmitted: (_) => _handleLogin(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF90A4AE),
                              size: 22,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            SizedBox(
                              height: 40,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: auth.isLoading
                                        ? null
                                        : (value) => setState(
                                              () =>
                                                  _rememberMe = value ?? false,
                                            ),
                                    activeColor: _primary,
                                  ),
                                  const Text(
                                    'Remember Me',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: _darkNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Sign In button
                        _SignInButton(
                          isLoading: auth.isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 20),

                        // OR divider
                        const _OrDivider(),
                        const SizedBox(height: 16),

                        // Continue with Google
                        _SocialButton(
                          onPressed: auth.isLoading ? null : _handleGoogle,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleColorIcon(),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _darkNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Login with Fingerprint
                        _SocialButton(
                          onPressed: auth.isLoading
                              ? null
                              : (_biometricEnabled
                                  ? _handleBiometricLogin
                                  : null),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.fingerprint_rounded,
                                size: 26,
                                color: _primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Login with Fingerprint',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _biometricEnabled
                                      ? _darkNavy
                                      : const Color(0xFFB0BEC5),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?  ",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF607D95),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/register'),
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                ),
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

            // ── Secure & Trusted footer ─────────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -24),
              child: const _SecureFooter(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _HospitalHeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 280 + topPad,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Image.asset(
                'assets/images/medicare_login_header.png',
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFBFDFF8), Color(0xFFDEEFFD)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Hospital building illustration
          Positioned(
            left: 0,
            right: 0,
            top: topPad + 70,
            bottom: 0,
            child: CustomPaint(
              painter: _HospitalBuildingPainter(),
            ),
          ),

          // Bottom wave cutout in white so card slides under it
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: 60,
            child: CustomPaint(painter: _WhiteBottomWavePainter()),
          ),
        ],
      ),
    );
  }
}

/// Painter that draws a simplified hospital building with glass windows
/// against the sky background — matches the image in the mockup.
class _HospitalBuildingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.86, w, h * 0.14),
      Paint()..color = const Color(0xFFD0E8F5),
    );

    // Main building body
    final bodyPaint = Paint()..color = const Color(0xFFE8F3FB);
    final bodyOutline = Paint()
      ..color = const Color(0xFFACC8DF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.18, w * 0.90, h * 0.70),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, bodyPaint);
    canvas.drawRRect(body, bodyOutline);

    // Blue roof bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.15, w * 0.90, h * 0.05),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF1266C5),
    );

    // "HOSPITAL" sign on roof
    const textSpan = TextSpan(
      text: '+ HOSPITAL',
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        letterSpacing: 1,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(w * 0.50 - tp.width / 2, h * 0.16));

    // Glass window grid
    final glassPaint = Paint()..color = const Color(0xFF7DB8E8);
    final frameStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const cols = 8;
    const rows = 3;
    final winW = w * 0.80 / cols;
    final winH = h * 0.36 / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          w * 0.10 + c * winW + winW * 0.1,
          h * 0.24 + r * (winH + h * 0.02),
          winW * 0.80,
          winH * 0.85,
        );
        canvas.drawRect(rect, glassPaint);
        canvas.drawRect(rect, frameStroke);
      }
    }

    // Entrance canopy
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.38, h * 0.77, w * 0.24, h * 0.03),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF0D47A1),
    );

    // Glass door
    canvas.drawRect(
      Rect.fromLTWH(w * 0.42, h * 0.80, w * 0.16, h * 0.06),
      Paint()..color = const Color(0xFF64B5E8),
    );

    // Trees
    final trunkPaint = Paint()..color = const Color(0xFF795548);
    final leafPaint = Paint()..color = const Color(0xFF2E7D32);
    // Left
    canvas.drawRect(
        Rect.fromLTWH(w * 0.02, h * 0.76, w * 0.025, h * 0.10), trunkPaint);
    canvas.drawCircle(Offset(w * 0.034, h * 0.74), w * 0.048, leafPaint);
    // Right
    canvas.drawRect(
        Rect.fromLTWH(w * 0.955, h * 0.76, w * 0.025, h * 0.10), trunkPaint);
    canvas.drawCircle(Offset(w * 0.968, h * 0.74), w * 0.048, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Paints a white wave at the bottom of the hero so the white card
/// appears to emerge from under it.
class _WhiteBottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = const Color(0xFFF1F6FC);
    final path = Path()
      ..moveTo(0, h * 0.55)
      ..quadraticBezierTo(w * 0.25, 0, w * 0.5, h * 0.40)
      ..quadraticBezierTo(w * 0.75, h * 0.75, w, h * 0.25)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// FORM WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FieldLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF183B5B)),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF183B5B),
          ),
        ),
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _LoginTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF183B5B),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFFADBBC8),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD6E2F0), width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD6E2F0), width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1266C5), width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2.0),
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
          backgroundColor: const Color(0xFF1266C5),
          disabledBackgroundColor:
              const Color(0xFF1266C5).withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          foregroundColor: const Color(0xFF183B5B),
          side: const BorderSide(color: Color(0xFF1266C5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledForegroundColor:
              const Color(0xFFB0BEC5).withValues(alpha: 0.8),
        ),
        child: child,
      ),
    );
  }
}

/// Multicolour 'G' icon replicating the Google logo colours.
class _GoogleColorIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Background circle (transparent — we just draw the 'G')
    // Arc segments: red, blue, yellow, green (simplified with 4 arcs)
    const colors = [
      Color(0xFF4285F4), // blue
      Color(0xFFEA4335), // red
      Color(0xFFFBBC05), // yellow
      Color(0xFF34A853), // green
    ];

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < 4; i++) {
      segmentPaint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.6),
        (3.14159 / 2) + i * (3.14159 * 2 / 4), // start angle
        3.14159 * 2 / 4 - 0.12,
        false,
        segmentPaint,
      );
    }

    // White bar for the "G" notch
    final barPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(
          c.dx, c.dy - size.width * 0.11, r * 0.62, size.width * 0.22),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFD6E2F0), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF90A4B8),
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFD6E2F0), thickness: 1)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFEF4444),
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

// ── Secure & Trusted footer ────────────────────────────────────────────────

class _SecureFooter extends StatelessWidget {
  const _SecureFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFF1266C5),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Icon(Icons.lock_rounded, color: Colors.white, size: 14),
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Secure & Trusted',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF607D95),
          ),
        ),
      ],
    );
  }
}
