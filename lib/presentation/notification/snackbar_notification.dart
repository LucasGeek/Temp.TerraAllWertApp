import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../responsive/breakpoints.dart';

/// Serviço global de Snackbar Notification
class SnackbarNotification {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = 
      GlobalKey<ScaffoldMessengerState>();

  /// Cria margem responsiva para o snackbar
  static EdgeInsets _getResponsiveMargin(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // Se for tablet ou maior (>= 768px), centraliza e limita a largura
    if (width >= Breakpoints.md) {
      final maxWidth = width * 0.6; // Máximo 60% da largura da tela
      final minWidth = 320.0; // Largura mínima para evitar overflow
      final finalWidth = maxWidth < minWidth ? minWidth : maxWidth;
      
      // Garante que a margem nunca seja negativa ou muito pequena
      final horizontalMargin = ((width - finalWidth) / 2).clamp(16.0, width * 0.2);
      
      return EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
        top: 16,
        bottom: 16,
      );
    }
    
    // Para mobile, usa toda a largura com margem padrão
    return const EdgeInsets.all(16);
  }

  static void showSuccess(String message) {
    final context = messengerKey.currentContext;
    if (context == null) return;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C1C1E), // Preto padrão
        behavior: SnackBarBehavior.floating,
        margin: _getResponsiveMargin(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  static void showError(String message) {
    final context = messengerKey.currentContext;
    if (context == null) return;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C1C1E), // Preto padrão
        behavior: SnackBarBehavior.floating,
        margin: _getResponsiveMargin(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
        elevation: 6,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.redAccent,
          onPressed: () {
            messengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  static void showInfo(String message) {
    final context = messengerKey.currentContext;
    if (context == null) return;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.lightBlueAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C1C1E), // Preto padrão
        behavior: SnackBarBehavior.floating,
        margin: _getResponsiveMargin(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  static void showWarning(String message) {
    final context = messengerKey.currentContext;
    if (context == null) return;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C1C1E), // Preto padrão
        behavior: SnackBarBehavior.floating,
        margin: _getResponsiveMargin(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }

  static void showLoading(String message) {
    final context = messengerKey.currentContext;
    if (context == null) return;

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C1C1E), // Preto padrão
        behavior: SnackBarBehavior.floating,
        margin: _getResponsiveMargin(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(days: 1), // Permanece até ser removido
        elevation: 6,
      ),
    );
  }

  static void hideLoading() {
    messengerKey.currentState?.hideCurrentSnackBar();
  }

  static void hideAll() {
    messengerKey.currentState?.clearSnackBars();
  }
}

/// Provider para o serviço de snackbar
final snackbarNotificationProvider = Provider<SnackbarNotification>((ref) {
  return SnackbarNotification();
});