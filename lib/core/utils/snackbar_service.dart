import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';

class SnackbarService {
  SnackbarService._();

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      AppColors.success,
      Icons.check_circle_outline,
    );
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.error, Icons.error_outline);
    HapticFeedback.vibrate();
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.primary, Icons.info_outline);
    HapticFeedback.lightImpact();
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    Color bgColor,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
