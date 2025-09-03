import 'package:flutter/material.dart';

class SnackbarNotification {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) {
    _showSnackbar(
      message: message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      icon: Icons.check_circle,
    );
  }

  static void showError(String message) {
    _showSnackbar(
      message: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      icon: Icons.error,
    );
  }

  static void showWarning(String message) {
    _showSnackbar(
      message: message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      icon: Icons.warning,
    );
  }

  static void showInfo(String message) {
    _showSnackbar(
      message: message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      icon: Icons.info,
    );
  }

  static void _showSnackbar({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 4),
  }) {
    final context = messengerKey.currentContext;
    if (context == null) return;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'OK',
          textColor: textColor,
          onPressed: () {
            messengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
