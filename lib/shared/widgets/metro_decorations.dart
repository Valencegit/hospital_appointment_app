import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Top wave decorative header curve seen in Metro Health Login and Registration screens.
class MetroTopWave extends StatelessWidget {
  final double height;

  const MetroTopWave({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TopWavePainter(),
      ),
    );
  }
}

class _TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background light blue curve
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.18),
          AppColors.primaryLight.withValues(alpha: 0.5),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final bgPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.7)
      ..quadraticBezierTo(w * 0.65, h * 1.05, w * 0.25, h * 0.55)
      ..quadraticBezierTo(w * 0.1, h * 0.4, 0, h * 0.6)
      ..close();

    canvas.drawPath(bgPath, bgPaint);

    // Foreground rich blue wave
    final fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF0C6CF2),
          Color(0xFF0052CC),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final fgPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.85, 0)
      ..quadraticBezierTo(w * 0.55, h * 0.85, 0, h * 0.45)
      ..close();

    canvas.drawPath(fgPath, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottom subtle blue curved wave seen in Metro Health Login screen.
class MetroBottomWave extends StatelessWidget {
  final double height;

  const MetroBottomWave({super.key, this.height = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BottomWavePainter(),
      ),
    );
  }
}

class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint1 = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(w * 0.3, h)
      ..quadraticBezierTo(w * 0.6, h * 0.2, w, h * 0.4)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF0B63E5),
          Color(0xFF004EC4),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path2 = Path()
      ..moveTo(w * 0.55, h)
      ..quadraticBezierTo(w * 0.75, h * 0.45, w, h * 0.55)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Architectural vector illustration of the modern Metro Health Hospital building
/// featured on the Splash screen.
class MetroHospitalBuildingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground shadow / base
    final groundPaint = Paint()..color = const Color(0xFFD6E2F0);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.88, w, h * 0.12), groundPaint);

    // Main Hospital Modern Building (center & left)
    final bldgPaint = Paint()..color = const Color(0xFFE8EEF5);
    final bldgOutline = Paint()
      ..color = const Color(0xFFB5C8DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final mainRect = Rect.fromLTWH(w * 0.08, h * 0.28, w * 0.84, h * 0.60);
    canvas.drawRRect(RRect.fromRectAndRadius(mainRect, const Radius.circular(8)), bldgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(mainRect, const Radius.circular(8)), bldgOutline);

    // Upper top trim
    final roofPaint = Paint()..color = const Color(0xFF0B63E5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.26, w * 0.84, h * 0.04),
        const Radius.circular(4),
      ),
      roofPaint,
    );

    // Blue glass windows rows
    final windowGlassPaint = Paint()..color = const Color(0xFF90BEEB);
    final windowFramePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const cols = 7;
    const rows = 3;
    final winW = (w * 0.72) / cols;
    final winH = (h * 0.38) / (rows + 1);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final winRect = Rect.fromLTWH(
          w * 0.14 + c * winW + winW * 0.1,
          h * 0.33 + r * (winH * 1.3),
          winW * 0.8,
          winH * 0.9,
        );
        canvas.drawRect(winRect, windowGlassPaint);
        canvas.drawRect(winRect, windowFramePaint);
      }
    }

    // Modern glass entrance / canopy
    final canopyPaint = Paint()..color = const Color(0xFF004EC4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.40, h * 0.76, w * 0.20, h * 0.03),
        const Radius.circular(3),
      ),
      canopyPaint,
    );

    final glassDoorPaint = Paint()..color = const Color(0xFF6BA6DF);
    canvas.drawRect(Rect.fromLTWH(w * 0.43, h * 0.79, w * 0.14, h * 0.09), glassDoorPaint);

    // Green landscaping / trees flanking the building
    final treePaint = Paint()..color = const Color(0xFF2E8B57);
    final trunkPaint = Paint()..color = const Color(0xFF8B5A2B);

    // Left tree
    canvas.drawRect(Rect.fromLTWH(w * 0.04, h * 0.80, w * 0.02, h * 0.08), trunkPaint);
    canvas.drawCircle(Offset(w * 0.05, h * 0.78), w * 0.05, treePaint);

    // Right tree
    canvas.drawRect(Rect.fromLTWH(w * 0.94, h * 0.80, w * 0.02, h * 0.08), trunkPaint);
    canvas.drawCircle(Offset(w * 0.95, h * 0.78), w * 0.05, treePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
