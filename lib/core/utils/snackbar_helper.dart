import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SnackBarHelper {
  SnackBarHelper._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppColors.success);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.error);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppColors.info);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppColors.warning);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
