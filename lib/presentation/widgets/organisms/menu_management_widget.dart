import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../providers/menu_management_provider.dart';
import '../molecules/menu_item_card.dart';
import '../../../domain/entities/navigation_item.dart';
import '../../../domain/enums/menu_presentation_type.dart';

class MenuManagementWidget extends ConsumerStatefulWidget {
  const MenuManagementWidget({super.key});

  @override
  ConsumerState<MenuManagementWidget> createState() => _MenuManagementWidgetState();
}

class _MenuManagementWidgetState extends ConsumerState<MenuManagementWidget> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _routeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  IconData _selectedIcon = Icons.home;
  bool _isVisible = true;
  bool _isEnabled = true;
  NavigationItem? _editingItem;

  @override
  void dispose() {
    _labelController.dispose();
    _routeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuManagementProvider);
    final menuNotifier = ref.read(menuManagementProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Menus'),
        actions: [
          if (menuState.isSyncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => menuNotifier.syncWithApi(),
              tooltip: 'Sincronizar com API',
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showMenuForm(context),
            tooltip: 'Adicionar Menu',
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (menuState.error != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(LayoutConstants.marginMd),
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: LayoutConstants.iconMedium,
                  ),
                  SizedBox(width: LayoutConstants.marginSm),
                  Expanded(
                    child: Text(
                      menuState.error!,
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: LayoutConstants.fontSizeMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => menuNotifier.clearError(),
                    color: AppTheme.errorColor,
                  ),
                ],
              ),
            ),

          // Last sync info
          if (menuState.lastSync != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: LayoutConstants.marginMd,
                vertical: LayoutConstants.marginSm,
              ),
              child: Text(
                'Última sincronização: ${_formatDateTime(menuState.lastSync!)}',
                style: TextStyle(
                  fontSize: LayoutConstants.fontSizeSmall,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Menu list
          Expanded(
            child: menuState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : menuState.items.isEmpty
                    ? _buildEmptyState(context)
                    : _buildMenuList(context, menuState.items, menuNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: LayoutConstants.marginLg),
          Text(
            'Nenhum menu encontrado',
            style: TextStyle(
              fontSize: LayoutConstants.fontSizeLarge,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: LayoutConstants.marginSm),
          Text(
            'Adicione o primeiro menu clicando no botão +',
            style: TextStyle(
              fontSize: LayoutConstants.fontSizeMedium,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: LayoutConstants.marginLg),
          ElevatedButton(
            onPressed: () => _showMenuForm(context),
            child: const Text('Adicionar Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(
    BuildContext context,
    List<NavigationItem> items,
    MenuManagementNotifier notifier,
  ) {
    return ReorderableListView.builder(
      padding: EdgeInsets.all(LayoutConstants.marginMd),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MenuItemCard(
          key: ValueKey(item.id),
          item: item,
          onEdit: () => _showMenuForm(context, item),
          onDelete: () => _showDeleteConfirmation(context, item, notifier),
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        
        final updatedItems = List<NavigationItem>.from(items);
        final item = updatedItems.removeAt(oldIndex);
        updatedItems.insert(newIndex, item);
        
        // Atualizar ordem
        for (int i = 0; i < updatedItems.length; i++) {
          updatedItems[i] = NavigationItem(
            id: updatedItems[i].id,
            label: updatedItems[i].label,
            icon: updatedItems[i].icon,
            selectedIcon: updatedItems[i].selectedIcon,
            route: updatedItems[i].route,
            order: i,
            isVisible: updatedItems[i].isVisible,
            isEnabled: updatedItems[i].isEnabled,
            description: updatedItems[i].description,
            parentId: updatedItems[i].parentId,
            menuType: updatedItems[i].menuType,
            permissions: updatedItems[i].permissions,
          );
        }
        
        notifier.reorderMenus(updatedItems);
      },
    );
  }

  void _showMenuForm(BuildContext context, [NavigationItem? item]) {
    _editingItem = item;
    
    if (item != null) {
      _labelController.text = item.label;
      _routeController.text = item.route;
      _descriptionController.text = item.description ?? '';
      _selectedIcon = item.icon;
      _isVisible = item.isVisible;
      _isEnabled = item.isEnabled;
    } else {
      _labelController.clear();
      _routeController.clear();
      _descriptionController.clear();
      _selectedIcon = Icons.home;
      _isVisible = true;
      _isEnabled = true;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item != null ? 'Editar Menu' : 'Adicionar Menu'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Menu',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: LayoutConstants.marginMd),
                  
                  TextFormField(
                    controller: _routeController,
                    decoration: const InputDecoration(
                      labelText: 'Rota',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Rota é obrigatória';
                      }
                      if (!value.startsWith('/')) {
                        return 'Rota deve começar com /';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: LayoutConstants.marginMd),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: LayoutConstants.marginMd),
                  
                  // Icon picker
                  Row(
                    children: [
                      Text(
                        'Ícone:',
                        style: TextStyle(
                          fontSize: LayoutConstants.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: LayoutConstants.marginSm),
                      GestureDetector(
                        onTap: () => _showIconPicker(context, setDialogState),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.outline),
                            borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                          ),
                          child: Icon(
                            _selectedIcon,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: LayoutConstants.marginMd),
                  
                  // Switches
                  SwitchListTile(
                    title: const Text('Visível'),
                    subtitle: const Text('Menu aparece na navegação'),
                    value: _isVisible,
                    onChanged: (value) => setDialogState(() => _isVisible = value),
                  ),
                  
                  SwitchListTile(
                    title: const Text('Habilitado'),
                    subtitle: const Text('Menu pode ser clicado'),
                    value: _isEnabled,
                    onChanged: (value) => setDialogState(() => _isEnabled = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            SizedBox(width: LayoutConstants.marginSm),
            ElevatedButton(
              onPressed: () => _saveMenu(context),
              child: Text(item != null ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context, StateSetter setDialogState) {
    final icons = [
      Icons.home,
      Icons.dashboard,
      Icons.settings,
      Icons.person,
      Icons.business,
      Icons.apartment,
      Icons.map,
      Icons.photo,
      Icons.video_collection,
      Icons.folder,
      Icons.description,
      Icons.analytics,
      Icons.help,
      Icons.info,
      Icons.menu,
      Icons.favorite,
      Icons.star,
      Icons.shopping_cart,
      Icons.notifications,
      Icons.search,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Ícone'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final icon = icons[index];
              return GestureDetector(
                onTap: () {
                  setDialogState(() => _selectedIcon = icon);
                  Navigator.of(context).pop();
                },
                child: Container(
                  margin: EdgeInsets.all(LayoutConstants.marginXs),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedIcon == icon 
                          ? AppTheme.primaryColor 
                          : AppTheme.outline,
                      width: _selectedIcon == icon ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: _selectedIcon == icon 
                        ? AppTheme.primaryColor 
                        : AppTheme.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _saveMenu(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(menuManagementProvider.notifier);

    final menu = NavigationItem(
      id: _editingItem?.id ?? 'menu_${DateTime.now().millisecondsSinceEpoch}',
      label: _labelController.text.trim(),
      icon: _selectedIcon,
      selectedIcon: _selectedIcon,
      route: _routeController.text.trim(),
      order: _editingItem?.order ?? 0,
      isVisible: _isVisible,
      isEnabled: _isEnabled,
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      menuType: MenuPresentationType.padrao,
    );

    bool success;
    if (_editingItem != null) {
      final result = await notifier.updateMenu(menu);
      success = result != null;
    } else {
      final result = await notifier.addMenu(menu);
      success = result != null;
    }

    if (success && context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingItem != null 
                ? 'Menu atualizado com sucesso' 
                : 'Menu adicionado com sucesso',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    NavigationItem item,
    MenuManagementNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o menu "${item.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          SizedBox(width: LayoutConstants.marginSm),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await notifier.deleteMenu(item.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Menu excluído com sucesso'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}