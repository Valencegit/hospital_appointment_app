import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

/// Outlined social sign-in button matching the mockup design.
///
/// Provide [assetPath] for an image logo (e.g. Google) or [icon] for a
/// Material icon (e.g. Apple, Phone). If [isDisabled] is true the button
/// renders greyed-out and the tap handler is ignored.
class SocialSignInButton extends StatelessWidget {
  final String label;
  final String? assetPath;   // e.g. 'assets/icons/google_logo.png'
  final IconData? icon;      // fallback when no image asset is available
  final VoidCallback? onPressed;
  final bool isDisabled;

  const SocialSignInButton({
    super.key,
    required this.label,
    this.assetPath,
    this.icon,
    required this.onPressed,
    this.isDisabled = false,
  }) : assert(assetPath != null || icon != null,
            'Provide either assetPath or icon');

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isDisabled ? AppColors.textMuted : AppColors.textPrimary;
    final borderColor = isDisabled ? AppColors.divider : AppColors.border;

    return SizedBox(
      height: AppConstants.buttonHeight,
      child: OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDisabled
              ? AppColors.surfaceVariant
              : AppColors.surface,
          foregroundColor: effectiveColor,
          side: BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / icon
            SizedBox(
              width: 22,
              height: 22,
              child: _buildLogo(isDisabled),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool disabled) {
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          BootstrapIcons.google,
          size: 22,
          color: disabled ? AppColors.textMuted : AppColors.primary,
        ),
      );
    }
    return Icon(
      icon,
      size: 20,
      color: disabled ? AppColors.textMuted : AppColors.textPrimary,
    );
  }
}
