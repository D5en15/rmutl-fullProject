import 'package:flutter/material.dart';

/// ✅ Unified toast/snackbar system for the whole app (Full width)
class AppToast {
  static void show(
    BuildContext context,
    String message, {
    Color? color,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final bgColor = color ?? theme.colorScheme.surfaceContainerHighest;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(icon, color: Colors.white),
              ),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.fixed, // 🟢 Full width
        backgroundColor: bgColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// ✅ Success notification
  static void success(BuildContext context, String message) =>
      show(context, message,
          color: Colors.green.shade600, icon: Icons.check_circle);

  /// ⚠️ Error notification
  static void error(BuildContext context, String message) =>
      show(context, message,
          color: Colors.red.shade600, icon: Icons.error);

  /// ℹ️ Info notification
  static void info(BuildContext context, String message) =>
      show(context, message,
          color: Colors.blue.shade600, icon: Icons.info_outline);
}