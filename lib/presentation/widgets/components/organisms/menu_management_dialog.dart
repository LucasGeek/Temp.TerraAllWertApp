import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/navigation_item.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../features/navigation/providers/navigation_provider.dart';
import '../../../notification/snackbar_notification.dart';
import '../../../responsive/breakpoints.dart';
import 'menu_crud_dialog.dart';

/// Dialog/BottomSheet para gerenciamento de menus existentes
/// Inclui lista hierárquica, edição, exclusão e reordenação drag-drop
class MenuManagementDialog extends ConsumerWidget {
  const MenuManagementDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;
    
    if (isMobile) {
      return _buildMobileBottomSheet(context, ref);
    } else {
      return _buildDesktopDialog(context, ref);
    }
  }

  /// BottomSheet para mobile
  Widget _buildMobileBottomSheet(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(LayoutConstants.radiusLarge),
          topRight: Radius.circular(LayoutConstants.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          Flexible(
            child: _buildContent(context, ref, isMobile: true),
          ),
        ],
      ),
    );
  }

  /// Dialog para desktop/tablet
  Widget _buildDesktopDialog(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        width: context.responsive<double>(
          xs: 500,
          md: 650,
          lg: 750,
          xl: 800,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        margin: EdgeInsets.all(LayoutConstants.marginXl),
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
        child: _buildContent(context, ref, isMobile: false),
      ),
    );
  }

  /// Conteúdo principal
  Widget _buildContent(BuildContext context, WidgetRef ref, {required bool isMobile}) {
    final navigationItems = ref.watch(navigationItemsProvider);
    
    return Padding(
      padding: EdgeInsets.all(LayoutConstants.paddingXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          
          SizedBox(height: LayoutConstants.marginXl),
          
          // Lista de menus com drag-drop
          Flexible(
            child: navigationItems.isEmpty
                ? _buildEmptyState()
                : _buildMenuList(context, ref, navigationItems),
          ),
          
          SizedBox(height: LayoutConstants.marginXl),
          
          // Botões de ação
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  /// Header do dialog
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
          ),
          child: const Icon(
            Icons.edit_note,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        
        SizedBox(width: LayoutConstants.marginMd),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gerenciar Menus',
                style: TextStyle(
                  fontSize: LayoutConstants.fontSizeXLarge,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              Text(
                'Edite, reordene ou exclua itens do menu',
                style: TextStyle(
                  fontSize: LayoutConstants.fontSizeSmall,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Lista de menus com funcionalidade drag-drop
  Widget _buildMenuList(BuildContext context, WidgetRef ref, List<NavigationItem> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) => _handleReorder(ref, items, oldIndex, newIndex),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildMenuListItem(context, ref, item, index);
        },
      ),
    );
  }

  /// Item da lista de menus
  Widget _buildMenuListItem(BuildContext context, WidgetRef ref, NavigationItem item, int index) {
    final bool isProtectedRoute = item.route.toLowerCase() == '/dashboard' || 
                                  item.route.toLowerCase() == 'dashboard';
    
    return Card(
      key: ValueKey(item.id),
      margin: EdgeInsets.symmetric(
        horizontal: LayoutConstants.paddingSm,
        vertical: LayoutConstants.paddingXs,
      ),
      child: ListTile(
        leading: SizedBox(
          width: 80,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Icon(
                Icons.drag_handle,
                color: AppTheme.textSecondary,
                size: LayoutConstants.iconMedium,
              ),
              SizedBox(width: LayoutConstants.marginSm),
              // Ícone do menu
              Icon(
                item.icon,
                color: item.isEnabled ? AppTheme.primaryColor : AppTheme.textSecondary,
                size: LayoutConstants.iconMedium,
              ),
            ],
          ),
        ),
        
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: item.isEnabled ? AppTheme.onSurface : AppTheme.textSecondary,
            decoration: item.isEnabled ? null : TextDecoration.lineThrough,
          ),
        ),
        
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rota: ${item.route}',
              style: TextStyle(
                fontSize: LayoutConstants.fontSizeSmall,
                color: AppTheme.textSecondary,
              ),
            ),
            if (item.description != null && item.description!.isNotEmpty) ...[
              SizedBox(height: LayoutConstants.marginXs),
              Text(
                item.description!,
                style: TextStyle(
                  fontSize: LayoutConstants.fontSizeSmall,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        
        trailing: SizedBox(
          width: 140,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status badges
              if (isProtectedRoute)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield,
                        size: 10,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Protegido',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              if (!item.isVisible && !isProtectedRoute)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Oculto',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // Botão editar
              IconButton(
                onPressed: () => _handleEditMenu(context, item),
                icon: const Icon(Icons.edit_outlined),
                color: AppTheme.infoColor,
                iconSize: LayoutConstants.iconMedium,
                splashRadius: LayoutConstants.iconSplashRadius,
                tooltip: isProtectedRoute ? 'Editar menu (rota protegida)' : 'Editar menu',
              ),
              
              // Botão excluir
              IconButton(
                onPressed: isProtectedRoute ? null : () => _handleDeleteMenu(context, ref, item),
                icon: const Icon(Icons.delete_outline),
                color: isProtectedRoute ? AppTheme.textSecondary : AppTheme.errorColor,
                iconSize: LayoutConstants.iconMedium,
                splashRadius: LayoutConstants.iconSplashRadius,
                tooltip: isProtectedRoute ? 'Rota protegida (não pode ser removida)' : 'Excluir menu',
              ),
            ],
          ),
        ),
        
        contentPadding: EdgeInsets.symmetric(
          horizontal: LayoutConstants.paddingMd,
          vertical: LayoutConstants.paddingSm,
        ),
      ),
    );
  }

  /// Estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_open,
            size: LayoutConstants.iconXLarge,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: LayoutConstants.marginLg),
          Text(
            'Nenhum menu cadastrado',
            style: TextStyle(
              fontSize: LayoutConstants.fontSizeLarge,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: LayoutConstants.marginSm),
          Text(
            'Crie um novo menu para começar',
            style: TextStyle(
              fontSize: LayoutConstants.fontSizeSmall,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Botões de ação
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          // Botão adicionar novo
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleAddNew(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.all(LayoutConstants.paddingMd),
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                ),
              ),
              icon: const Icon(
                Icons.add,
                color: AppTheme.primaryColor,
              ),
              label: const Text(
                'Novo Menu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          
          SizedBox(width: LayoutConstants.marginMd),
          
          // Botão fechar
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.all(LayoutConstants.paddingMd),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                ),
              ),
              child: const Text(
                'Fechar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle visual para mobile
  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: LayoutConstants.marginMd),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.outline,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Handler para reordenação drag-drop
  void _handleReorder(WidgetRef ref, List<NavigationItem> items, int oldIndex, int newIndex) {
    // Ajustar newIndex se necessário (padrão do Flutter)
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    // Criar nova lista reordenada
    final reorderedItems = List<NavigationItem>.from(items);
    final item = reorderedItems.removeAt(oldIndex);
    reorderedItems.insert(newIndex, item);
    
    // Atualizar os orders
    final updatedItems = reorderedItems.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();
    
    // Aplicar reordenação
    ref.read(navigationItemsProvider.notifier).reorderNavigationItems(updatedItems);
    
    SnackbarNotification.showInfo('Menu reordenado com sucesso!');
  }

  /// Handler para adicionar novo menu
  void _handleAddNew(BuildContext context) {
    Navigator.of(context).pop(); // Fechar dialog atual
    _showCreateMenuDialog(context);
  }

  /// Handler para editar menu
  void _handleEditMenu(BuildContext context, NavigationItem item) {
    // Proteger rota principal do dashboard da edição da rota
    if (item.route.toLowerCase() == '/dashboard' || item.route.toLowerCase() == 'dashboard') {
      Navigator.of(context).pop(); // Fechar dialog atual
      _showEditMenuDialog(context, item, isProtectedRoute: true);
    } else {
      Navigator.of(context).pop(); // Fechar dialog atual
      _showEditMenuDialog(context, item);
    }
  }

  /// Mostra dialog de criação de menu
  void _showCreateMenuDialog(BuildContext context) {
    final isMobile = context.isMobile;
    
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

  /// Mostra dialog de edição de menu
  void _showEditMenuDialog(BuildContext context, NavigationItem item, {bool isProtectedRoute = false}) {
    final isMobile = context.isMobile;
    
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MenuCrudDialog(
          itemToEdit: item, 
          isEditing: true,
          isProtectedRoute: isProtectedRoute,
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (context) => MenuCrudDialog(
          itemToEdit: item, 
          isEditing: true,
          isProtectedRoute: isProtectedRoute,
        ),
      );
    }
  }

  /// Handler para excluir menu com confirmação
  void _handleDeleteMenu(BuildContext context, WidgetRef ref, NavigationItem item) {
    // Proteger rota principal do dashboard
    if (item.route.toLowerCase() == '/dashboard' || item.route.toLowerCase() == 'dashboard') {
      _showProtectedRouteDialog(context);
      return;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Confirmar Exclusão',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja excluir o menu "${item.label}"?'),
            SizedBox(height: LayoutConstants.marginMd),
            Container(
              padding: EdgeInsets.all(LayoutConstants.paddingMd),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: AppTheme.warningColor,
                    size: LayoutConstants.iconMedium,
                  ),
                  SizedBox(width: LayoutConstants.marginSm),
                  Expanded(
                    child: Text(
                      'Esta ação não pode ser desfeita.',
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeSmall,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _confirmDeleteMenu(ref, item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              ),
            ),
            child: const Text(
              'Excluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirma e executa exclusão do menu
  void _confirmDeleteMenu(WidgetRef ref, NavigationItem item) {
    try {
      ref.read(navigationItemsProvider.notifier).removeNavigationItem(item.id);
      SnackbarNotification.showSuccess('Menu "${item.label}" excluído com sucesso!');
    } catch (e) {
      SnackbarNotification.showError('Erro ao excluir menu: $e');
    }
  }

  /// Mostra dialog informando que a rota é protegida
  void _showProtectedRouteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.shield,
              color: AppTheme.primaryColor,
              size: LayoutConstants.iconMedium,
            ),
            SizedBox(width: LayoutConstants.marginSm),
            const Text(
              'Rota Protegida',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A rota "Dashboard" é a rota principal do aplicativo e não pode ser removida.'),
            SizedBox(height: LayoutConstants.marginMd),
            Container(
              padding: EdgeInsets.all(LayoutConstants.paddingMd),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.infoColor,
                    size: LayoutConstants.iconMedium,
                  ),
                  SizedBox(width: LayoutConstants.marginSm),
                  Expanded(
                    child: Text(
                      'Você pode editar o nome e ícone, mas a rota permanecerá protegida.',
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeSmall,
                        color: AppTheme.infoColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              ),
            ),
            child: const Text(
              'Entendi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Método estático para mostrar o dialog
  static void show(BuildContext context) {
    final isMobile = context.isMobile;
    
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
}