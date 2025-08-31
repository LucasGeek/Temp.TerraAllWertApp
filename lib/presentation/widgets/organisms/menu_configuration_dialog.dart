import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';
import 'menu_crud_dialog.dart';
import 'menu_management_dialog.dart';

/// Dialog/BottomSheet inicial para configuração de menus
/// Mobile: BottomSheet, Desktop/Tablet: Dialog
class MenuConfigurationDialog extends StatelessWidget {
  const MenuConfigurationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile || (context.isTablet && context.isXs);

    if (isMobile) {
      return _buildMobileBottomSheet(context);
    } else {
      return _buildDesktopDialog(context);
    }
  }

  /// BottomSheet para mobile
  Widget _buildMobileBottomSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingXl),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(LayoutConstants.radiusLarge),
          topRight: Radius.circular(LayoutConstants.radiusLarge),
        ),
      ),
      child: _buildContent(context, isMobile: true),
    );
  }

  /// Dialog para desktop/tablet
  Widget _buildDesktopDialog(BuildContext context) {
    return Center(
      child: Container(
        width: context.responsive<double>(xs: 340, md: 450, lg: 500, xl: 550),
        margin: EdgeInsets.all(LayoutConstants.marginXl),
        padding: EdgeInsets.all(LayoutConstants.paddingXl),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: LayoutConstants.shadowBlurLarge,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildContent(context, isMobile: false),
      ),
    );
  }

  /// Conteúdo comum do dialog
  Widget _buildContent(BuildContext context, {required bool isMobile}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle visual para mobile
        if (isMobile) _buildHandle(),
        if (isMobile) SizedBox(height: LayoutConstants.marginMd),

        // Ícone do header
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.edit_note, color: AppTheme.primaryColor, size: 32),
        ),

        SizedBox(height: LayoutConstants.marginLg),

        // Título
        const Text(
          'Configuração do Menu',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
        ),

        SizedBox(height: LayoutConstants.marginSm),

        // Instrução
        const Text(
          'Escolha uma das opções abaixo para continuar:',
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: LayoutConstants.marginXl),

        // Opções do menu
        _buildMenuOption(
          context,
          icon: Icons.add_circle_outline,
          title: 'Criar Novo Menu',
          subtitle: 'Adicionar um novo item ao menu de navegação',
          onTap: () => _handleCreateNewMenu(context),
        ),

        SizedBox(height: LayoutConstants.marginMd),

        _buildMenuOption(
          context,
          icon: Icons.edit_outlined,
          title: 'Editar Menus',
          subtitle: 'Gerenciar, editar e reordenar menus existentes',
          onTap: () => _handleManageMenus(context),
        ),

        SizedBox(height: LayoutConstants.marginXl),

        // Botão Cancelar
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.all(LayoutConstants.paddingMd),
              side: const BorderSide(color: AppTheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
            ),
          ),
        ),

        // Espaçamento adicional para mobile
        if (isMobile) SizedBox(height: LayoutConstants.marginLg),
      ],
    );
  }

  /// Widget para opção do menu
  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(LayoutConstants.paddingMd),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.outline),
            borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: LayoutConstants.iconLarge),
              ),

              SizedBox(width: LayoutConstants.marginMd),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),

                    SizedBox(height: LayoutConstants.marginXs),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeSmall,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: LayoutConstants.iconMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle visual para mobile
  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2)),
    );
  }

  /// Handler para criar novo menu
  void _handleCreateNewMenu(BuildContext context) {
    Navigator.of(context).pop(); // Fechar dialog atual
    _showCreateMenuDialog(context);
  }

  /// Handler para gerenciar menus
  void _handleManageMenus(BuildContext context) {
    Navigator.of(context).pop(); // Fechar dialog atual
    _showManagementDialog(context);
  }

  /// Mostra dialog de criação de menu
  void _showCreateMenuDialog(BuildContext context) {
    final isMobile = context.isMobile || (context.isTablet && context.isXs);

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const MenuCrudDialog(),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (context) => const MenuCrudDialog(),
      );
    }
  }

  /// Mostra dialog de gerenciamento de menus
  void _showManagementDialog(BuildContext context) {
    final isMobile = context.isMobile || (context.isTablet && context.isXs);

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const MenuManagementDialog(),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (context) => const MenuManagementDialog(),
      );
    }
  }

  /// Método estático para mostrar o dialog
  static void show(BuildContext context) {
    final isMobile = context.isMobile || (context.isTablet && context.isXs);

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const MenuConfigurationDialog(),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (context) => const MenuConfigurationDialog(),
      );
    }
  }
}
