import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';
import '../../../../providers/menu_provider.dart';
import './create_menu_dialog.dart';

/// Organism: Dialog de configuração de menus
class MenuConfigurationDialog extends ConsumerStatefulWidget {
  const MenuConfigurationDialog({super.key});
  
  /// Método estático para mostrar o dialog
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const MenuConfigurationDialog(),
    );
  }

  @override
  ConsumerState<MenuConfigurationDialog> createState() => _MenuConfigurationDialogState();
}

class _MenuConfigurationDialogState extends ConsumerState<MenuConfigurationDialog> {
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      child: Container(
        width: isDesktop ? 600 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: isDesktop ? 600 : MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(LayoutConstants.radiusMedium),
          topRight: Radius.circular(LayoutConstants.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book,
            color: AppTheme.onPrimary,
            size: LayoutConstants.iconLarge,
          ),
          SizedBox(width: LayoutConstants.marginSm),
          Expanded(
            child: Text(
              'Configuração de Menus',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close, color: AppTheme.onPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção de Ações Rápidas
          _buildSectionTitle(context, 'Ações de Menu', Icons.menu),
          SizedBox(height: LayoutConstants.marginMd),
          
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Botão Criar Novo Menu
        _buildActionCard(
          context: context,
          icon: Icons.add_circle_outline,
          title: 'Criar Novo Menu',
          subtitle: 'Adicionar um novo menu ao sistema',
          color: Colors.green,
          onTap: () => _showCreateMenuDialog(context),
        ),
        
        SizedBox(height: LayoutConstants.marginMd),
        
        // Botão Editar/Reordenar Menus
        _buildActionCard(
          context: context,
          icon: Icons.edit,
          title: 'Editar Menus',
          subtitle: 'Modificar e reordenar menus existentes',
          color: Colors.blue,
          onTap: () => _showEditMenuMode(context),
        ),
        
        SizedBox(height: LayoutConstants.marginMd),
        
        // Botão Reordenar
        _buildActionCard(
          context: context,
          icon: Icons.reorder,
          title: 'Modo Reordenação',
          subtitle: 'Arrastar e soltar para reorganizar menus',
          color: Colors.orange,
          onTap: () => _showReorderMode(context),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
      child: Container(
        padding: EdgeInsets.all(LayoutConstants.paddingMd),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(LayoutConstants.paddingSm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: LayoutConstants.marginMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  SizedBox(height: LayoutConstants.marginXs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        SizedBox(width: LayoutConstants.marginXs),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }





  Future<void> _showCreateMenuDialog(BuildContext context) async {
    // Fechar o modal atual primeiro
    Navigator.of(context).pop();
    
    final result = await CreateMenuDialog.show(context);
    
    if (result == true && mounted) {
      // Recarregar menus se um novo foi criado
      await ref.read(menuProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Novo menu criado! Recarregando lista...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showEditMenuMode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modo de edição será implementado em breve'),
        backgroundColor: Colors.blue,
      ),
    );
    
    // TODO: Implementar tela de edição de menus
    // Navigator.push(context, MaterialPageRoute(builder: (_) => EditMenusPage()));
  }

  void _showReorderMode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modo de reordenação será implementado em breve'),
        backgroundColor: Colors.orange,
      ),
    );
    
    // TODO: Implementar modo drag & drop para reordenação
    // Navigator.push(context, MaterialPageRoute(builder: (_) => ReorderMenusPage()));
  }

}