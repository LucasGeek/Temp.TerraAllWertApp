import 'package:flutter/material.dart';

import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../notification/snackbar_notification.dart';

/// Footer de navegação com ações do usuário
/// Contém logout, settings e editar menu
class NavigationFooter extends StatelessWidget {
  final VoidCallback onLogoutTap;

  const NavigationFooter({super.key, required this.onLogoutTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        border: Border(top: BorderSide(width: LayoutConstants.strokeThin)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(icon: Icons.logout, tooltip: 'Logout', onTap: onLogoutTap),
          _buildActionButton(
            icon: Icons.settings,
            tooltip: 'Configurações',
            onTap: _handleSettings,
          ),
          _buildActionButton(icon: Icons.edit, tooltip: 'Editar Menu', onTap: _handleEditMenu),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppTheme.onPrimary, size: LayoutConstants.iconLarge),
      tooltip: tooltip,
      splashRadius: LayoutConstants.iconSplashRadius,
    );
  }

  void _handleSettings() {
    SnackbarNotification.showInfo('Configurações em desenvolvimento');
  }

  void _handleEditMenu() {
    SnackbarNotification.showInfo('Editar menu em desenvolvimento');
  }
}
