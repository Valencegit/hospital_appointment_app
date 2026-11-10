import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/metro_decorations.dart';

/// Metro Health Hospital animated splash screen matching Mockup Screen 1.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    Timer(AppConstants.splashDuration, _checkAuthAndNavigate);
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAuthenticated) {
      final role = authProvider.currentRole;
      if (role.isPatient) {
        context.go('/patient-home');
      } else if (role.isStaff) {
        context.go('/staff-home');
      } else if (role.isAdmin) {
        context.go('/admin-home');
      } else {
        context.go('/patient-home');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE8F1FC),
              Color(0xFFF6FAFF),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Upper Central Branding
              Positioned(
                top: size.height * 0.10,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Full MediCare logo — PNG asset when available,
                        // painted cross fallback otherwise
                        AppLogo(size: 160, showShadow: true),
                        SizedBox(height: 20),
                        Text(
                          'MediCare',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF183B5B),
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Hospital Appointment System',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1266C5),
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Your Health, Our Priority',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Architectural Hospital Building Facade Illustration
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: size.height * 0.28,
                  child: CustomPaint(
                    painter: MetroHospitalBuildingPainter(),
                  ),
                ),
              ),

              // Curved Royal Blue Bottom Wave with Loading Spinner
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gradient curved wave
                      ClipPath(
                        clipper: _SplashWaveClipper(),
                        child: Container(
                          height: 110,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF0C6CF2),
                                Color(0xFF0052CC),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      // Circular loading indicator inside the wave
                      const Positioned(
                        bottom: 26,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ],
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

class _SplashWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0, h * 0.35);
    path.quadraticBezierTo(w * 0.5, 0, w, h * 0.45);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
