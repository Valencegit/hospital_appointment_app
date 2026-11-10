import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Asset path constants — change only here if the file is renamed or moved
// ─────────────────────────────────────────────────────────────────────────────
class _LogoAssets {
  /// Full MediCare logo (heart + stethoscope + hospital building + calendar).
  /// Drop the PNG at this path and it shows automatically everywhere.
  static const String full = 'assets/images/medicare_logo.png';

  /// Square icon-only version used for small headers / notifications.
  /// Optional — falls back to the full logo if this file doesn't exist.
  static const String icon = 'assets/images/medicare_logo_icon.png';
}

// ─────────────────────────────────────────────────────────────────────────────
// AppLogo — full MediCare logo with graceful fallback to painted cross
// ─────────────────────────────────────────────────────────────────────────────

/// Displays the MediCare full logo image.
///
/// If the PNG asset has not been added yet, falls back to the painted
/// blue cross + ECG emblem so the app compiles and runs at any time.
///
/// Usage:
/// ```dart
/// // Large splash version
/// AppLogo(size: 180)
///
/// // Small dashboard header version
/// AppLogo(size: 48, showShadow: true)
/// ```
class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  final bool withBackground;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showShadow = false,
    this.withBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = _AssetLogoImage(
      assetPath: _LogoAssets.full,
      size: size,
      fallback: _PaintedCrossLogo(size: size),
    );

    if (showShadow) {
      logo = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: logo,
      );
    }

    if (withBackground) {
      return Container(
        width: size * 1.35,
        height: size * 1.35,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Center(child: logo),
      );
    }

    return logo;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppLogoIcon — small icon-only version for headers and notifications
// ─────────────────────────────────────────────────────────────────────────────

/// Small icon version of the logo (icon crop only).
/// Falls back to the full logo, then to the painted cross.
class AppLogoIcon extends StatelessWidget {
  final double size;
  final bool showShadow;

  const AppLogoIcon({super.key, this.size = 36, this.showShadow = false});

  @override
  Widget build(BuildContext context) {
    Widget logo = _AssetLogoImage(
      assetPath: _LogoAssets.icon,
      size: size,
      fallback: _AssetLogoImage(
        assetPath: _LogoAssets.full,
        size: size,
        fallback: _PaintedCrossLogo(size: size),
      ),
    );

    if (showShadow) {
      logo = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: logo,
      );
    }

    return logo;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MetroHealthHeader — branded header block used on auth screens
// ─────────────────────────────────────────────────────────────────────────────

/// Full branded header: logo + "MediCare" title + optional tagline.
/// Drop-in replacement wherever the old MetroHealthHeader was used.
class MetroHealthHeader extends StatelessWidget {
  final double logoSize;
  final bool showTagline;
  final String? subtitle;

  const MetroHealthHeader({
    super.key,
    this.logoSize = 100,
    this.showTagline = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize, showShadow: true),
        const SizedBox(height: 14),
        const Text(
          'MediCare',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF183B5B),
            letterSpacing: -0.3,
            height: 1.1,
          ),
        ),
        const Text(
          'Hospital Appointment System',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1266C5),
            letterSpacing: 0.2,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            subtitle ?? 'Your Health, Our Priority',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF607D95),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Tries to load [assetPath]; renders [fallback] if the asset doesn't exist.
class _AssetLogoImage extends StatelessWidget {
  final String assetPath;
  final double size;
  final Widget fallback;

  const _AssetLogoImage({
    required this.assetPath,
    required this.size,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// Original painted blue medical cross with ECG pulse line.
/// Used as the fallback until the PNG asset is added.
class _PaintedCrossLogo extends StatelessWidget {
  final double size;
  const _PaintedCrossLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MetroHospitalCrossPainter(color: AppColors.primary),
    );
  }
}

class _MetroHospitalCrossPainter extends CustomPainter {
  final Color color;
  _MetroHospitalCrossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final barThickness = w * 0.36;
    final cornerRadius = Radius.circular(w * 0.09);

    final crossPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final crossPath = Path();
    crossPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH((w - barThickness) / 2, 0, barThickness, h),
      cornerRadius,
    ));
    crossPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (h - barThickness) / 2, w, barThickness),
      cornerRadius,
    ));
    canvas.drawPath(crossPath, crossPaint);

    final pulsePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = (w * 0.05).clamp(2.5, 5.0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerY = h / 2;
    final pulsePath = Path();
    pulsePath.moveTo(w * 0.08, centerY);
    pulsePath.lineTo(w * 0.30, centerY);
    pulsePath.lineTo(w * 0.36, centerY + h * 0.06);
    pulsePath.lineTo(w * 0.47, centerY - h * 0.16);
    pulsePath.lineTo(w * 0.56, centerY + h * 0.16);
    pulsePath.lineTo(w * 0.65, centerY - h * 0.07);
    pulsePath.lineTo(w * 0.72, centerY);
    pulsePath.lineTo(w * 0.92, centerY);
    canvas.drawPath(pulsePath, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _MetroHospitalCrossPainter old) =>
      old.color != color;
}
