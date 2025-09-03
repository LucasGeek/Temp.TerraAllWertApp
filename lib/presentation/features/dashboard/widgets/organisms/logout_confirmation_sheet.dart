import 'package:flutter/material.dart';
import '../../../../layout/widgets/organisms/app_dialog.dart';

/// Classe para confirmação de logout usando AppDialog
class LogoutConfirmationSheet {
  /// Método estático para mostrar o dialog de confirmação de logout
  static Future<void> show(BuildContext context, {required VoidCallback onConfirmLogout}) async {
    final result = await context.showConfirmDialog(
      title: 'Confirmar Logout',
      message: 'Tem certeza que deseja sair do aplicativo?',
      confirmText: 'Sair',
      cancelText: 'Cancelar',
      icon: Icons.logout,
      isDangerous: true, // Botão vermelho para ação perigosa
    );
    
    if (result == true) {
      onConfirmLogout();
    }
  }
}