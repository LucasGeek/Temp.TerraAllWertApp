import 'package:flutter/material.dart';

import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../notification/snackbar_notification.dart';
import '../../../responsive/breakpoints.dart';
import 'logout_confirmation_sheet.dart';

/// Footer de navegação com ações do usuário
/// Contém logout, settings e editar menu
class NavigationFooter extends StatelessWidget {
  final VoidCallback onLogoutTap;
  final bool shouldCloseDrawer;

  const NavigationFooter({
    super.key, 
    required this.onLogoutTap,
    this.shouldCloseDrawer = false,
  });

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
          _buildActionButton(
            icon: Icons.logout, 
            tooltip: 'Logout', 
            onTap: () => _showLogoutConfirmation(context),
          ),
          _buildActionButton(
            icon: Icons.settings,
            tooltip: 'Configurações',
            onTap: () => _handleSettings(context),
          ),
          _buildActionButton(
            icon: Icons.edit, 
            tooltip: 'Editar Menu', 
            onTap: () => _handleEditMenu(context),
          ),
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

  void _showLogoutConfirmation(BuildContext context) {
    LogoutConfirmationSheet.show(
      context,
      onConfirmLogout: onLogoutTap,
    );
  }

  void _handleSettings(BuildContext context) {
    _closeDrawerIfNeeded(context);
    SnackbarNotification.showInfo('Configurações em desenvolvimento');
  }

  void _handleEditMenu(BuildContext context) {
    _closeDrawerIfNeeded(context);
    SnackbarNotification.showInfo('Editar menu em desenvolvimento');
  }

  void _closeDrawerIfNeeded(BuildContext context) {
    // Auto-detecta se é mobile/tablet e fecha drawer se necessário
    final isMobile = context.isMobile || (context.isTablet && context.isXs);
    
    if ((shouldCloseDrawer || isMobile) && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
