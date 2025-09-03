import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dashboard/widgets/organisms/create_menu_dialog.dart';
import '../../../features/dashboard/widgets/organisms/logout_confirmation_sheet.dart';
import '../../../features/dashboard/widgets/organisms/menu_configuration_dialog.dart';
import '../../../features/dashboard/widgets/organisms/settings_modal.dart';
import '../../../providers/navigation_provider.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';

/// Footer de navegação com ações do usuário
/// Contém logout, settings e adicionar/editar menu
class NavigationFooter extends ConsumerWidget {
  final VoidCallback onLogoutTap;
  final bool shouldCloseDrawer;

  const NavigationFooter({super.key, required this.onLogoutTap, this.shouldCloseDrawer = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa se há menus configurados
    final navigationItems = ref.watch(navigationItemsProvider);
    final hasMenus = navigationItems.isNotEmpty;

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
          // Botão adaptativo - FAB de adicionar ou botão de editar
          hasMenus
              ? _buildActionButton(
                  icon: Icons.edit,
                  tooltip: 'Editar Menu',
                  onTap: () => _handleEditMenu(context),
                )
              : _buildAddMenuFAB(onTap: () => _handleAddMenu(context)),
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

  /// Botão FAB estilizado para adicionar menu quando não há nenhum configurado
  Widget _buildAddMenuFAB({required VoidCallback onTap}) {
    return Tooltip(
      message: 'Adicionar Menu',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.secondaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: AppTheme.secondaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: AppTheme.onSecondary.withValues(alpha: 0.2),
            highlightColor: AppTheme.onSecondary.withValues(alpha: 0.1),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: const Icon(Icons.add_rounded, color: AppTheme.onSecondary, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    LogoutConfirmationSheet.show(context, onConfirmLogout: onLogoutTap);
  }

  Future<void> _handleSettings(BuildContext context) async {
    _closeDrawerIfNeeded(context);

    final result = await SettingsModal.show(context);

    if (result == true && context.mounted) {
      // Configurações salvas - não precisa de ação adicional
      // O próprio modal já mostra o feedback
    }
  }

  Future<void> _handleEditMenu(BuildContext context) async {
    _closeDrawerIfNeeded(context);

    final result = await MenuConfigurationDialog.show(context);

    if (result == true && context.mounted) {
      // Configurações de menu salvas - não precisa de ação adicional
      // O próprio dialog já mostra o feedback
    }
  }

  Future<void> _handleAddMenu(BuildContext context) async {
    _closeDrawerIfNeeded(context);

    final result = await CreateMenuDialog.show(context);

    if (result == true && context.mounted) {
      // Menu criado com sucesso - não precisa de ação adicional
      // O próprio dialog já mostra o feedback e navega
    }
  }

  void _closeDrawerIfNeeded(BuildContext context) {
    // Auto-detecta se é mobile/tablet e fecha drawer se necessário
    final isMobile = context.isMobile || (context.isTablet && context.isXs);

    if ((shouldCloseDrawer || isMobile) && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
