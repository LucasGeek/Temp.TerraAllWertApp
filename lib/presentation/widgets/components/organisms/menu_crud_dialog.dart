import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/navigation_item.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../features/navigation/providers/navigation_provider.dart';
import '../../../notification/snackbar_notification.dart';
import '../../../responsive/breakpoints.dart';

/// Dialog/BottomSheet para criar/editar menus
/// Adaptado das regras do menu legado
class MenuCrudDialog extends ConsumerStatefulWidget {
  final NavigationItem? itemToEdit;
  final bool isEditing;
  final bool isProtectedRoute;

  const MenuCrudDialog({
    super.key,
    this.itemToEdit,
    this.isEditing = false,
    this.isProtectedRoute = false,
  });

  @override
  ConsumerState<MenuCrudDialog> createState() => _MenuCrudDialogState();
}

class _MenuCrudDialogState extends ConsumerState<MenuCrudDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedMenuType = 'Menu Padrão';
  String? _selectedParentId;
  IconData _selectedIcon = Icons.home_outlined;
  IconData _selectedSelectedIcon = Icons.home;
  bool _isLoading = false;

  // Tipos de menu baseados no sistema legado
  final List<String> _menuTypes = [
    'Menu Padrão',
    'Menu com Pins', 
    'Menu Pavimento',
  ];

  // Ícones disponíveis
  final List<IconData> _availableIcons = [
    // Ícones principais solicitados
    Icons.menu_book, Icons.menu_book_outlined,
    Icons.architecture, Icons.architecture_outlined,
    Icons.description, Icons.description_outlined,
    Icons.location_on, Icons.location_on_outlined,
    Icons.house, Icons.house_outlined,
    Icons.apartment, Icons.apartment_outlined,
    Icons.local_parking, Icons.local_parking_outlined,
    Icons.villa, Icons.villa_outlined,
    
    // Ícones gerais úteis
    Icons.home, Icons.home_outlined,
    Icons.dashboard, Icons.dashboard_outlined,
    Icons.menu, Icons.menu_outlined,
    Icons.settings, Icons.settings_outlined,
    Icons.business, Icons.business_outlined,
    Icons.explore, Icons.explore_outlined,
    Icons.map, Icons.map_outlined,
    Icons.directions, Icons.directions_outlined,
    Icons.photo_library, Icons.photo_library_outlined,
    Icons.video_library, Icons.video_library_outlined,
    Icons.article, Icons.article_outlined,
    Icons.folder, Icons.folder_outlined,
    Icons.info, Icons.info_outlined,
    Icons.star, Icons.star_outlined,
    Icons.favorite, Icons.favorite_outlined,
    Icons.build, Icons.build_outlined,
    Icons.group, Icons.group_outlined,
    Icons.account_circle, Icons.account_circle_outlined,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.itemToEdit != null) {
      _loadItemData();
    }
  }

  void _loadItemData() {
    final item = widget.itemToEdit!;
    _titleController.text = item.label;
    _descriptionController.text = item.description ?? '';
    _selectedIcon = item.icon;
    _selectedSelectedIcon = item.selectedIcon;
    _selectedParentId = item.parentId; // Carregar ID do menu pai
    _selectedMenuType = item.menuType; // Carregar tipo de menu
  }

  /// Gera rota automaticamente baseada no título usando regex
  /// Evita duplicatas adicionando números sequenciais quando necessário
  String _generateRoute(String title, List<NavigationItem> existingItems, {String? currentItemId}) {
    if (title.trim().isEmpty) return '/';
    
    // Convert para minúsculo e remove acentos
    String route = title
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n');
    
    // Remove caracteres especiais e substitui espaços por hífens
    route = route
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove caracteres especiais
        .replaceAll(RegExp(r'\s+'), '-') // Substitui espaços por hífens
        .replaceAll(RegExp(r'-+'), '-'); // Remove hífens duplicados
    
    // Remove hífens no início e fim
    route = route.replaceAll(RegExp(r'^-+|-+$'), '');
    
    // Garante que comece com /
    String baseRoute = '/$route';
    
    // Verifica duplicatas e adiciona número se necessário
    return _ensureUniqueRoute(baseRoute, existingItems, currentItemId: currentItemId);
  }

  /// Garante que a rota seja única adicionando números sequenciais
  String _ensureUniqueRoute(String baseRoute, List<NavigationItem> existingItems, {String? currentItemId}) {
    // Filtra itens existentes, excluindo o item atual se estiver editando
    final existingRoutes = existingItems
        .where((item) => currentItemId == null || item.id != currentItemId)
        .map((item) => item.route)
        .toSet();
    
    // Se a rota base não existe, usa ela
    if (!existingRoutes.contains(baseRoute)) {
      return baseRoute;
    }
    
    // Procura por um número sequencial disponível
    int counter = 2;
    String candidateRoute;
    
    do {
      candidateRoute = '$baseRoute-$counter';
      counter++;
    } while (existingRoutes.contains(candidateRoute));
    
    return candidateRoute;
  }

  /// Gera apenas a rota base sem verificação de duplicatas (para comparação)
  String _generateBaseRoute(String title) {
    if (title.trim().isEmpty) return '/';
    
    // Convert para minúsculo e remove acentos
    String route = title
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n');
    
    // Remove caracteres especiais e substitui espaços por hífens
    route = route
        .replaceAll(RegExp(r'[^\w\s-]'), '') // Remove caracteres especiais
        .replaceAll(RegExp(r'\s+'), '-') // Substitui espaços por hífens
        .replaceAll(RegExp(r'-+'), '-'); // Remove hífens duplicados
    
    // Remove hífens no início e fim
    route = route.replaceAll(RegExp(r'^-+|-+$'), '');
    
    // Garante que comece com /
    return '/$route';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    
    if (isMobile) {
      return _buildMobileBottomSheet(context);
    } else {
      return _buildDesktopDialog(context);
    }
  }

  /// BottomSheet para mobile
  Widget _buildMobileBottomSheet(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(LayoutConstants.paddingXl),
                child: _buildForm(context, isMobile: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog para desktop/tablet
  Widget _buildDesktopDialog(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: context.responsive<double>(
            xs: 400,
            md: 500,
            lg: 600,
            xl: 650,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(LayoutConstants.paddingXl),
                  child: _buildForm(context, isMobile: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formulário principal
  Widget _buildForm(BuildContext context, {required bool isMobile}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isEditing ? Icons.edit : Icons.add,
                color: AppTheme.primaryColor,
                size: LayoutConstants.iconLarge,
              ),
              SizedBox(width: LayoutConstants.marginSm),
              Expanded(
                child: Text(
                  widget.isEditing ? 'Editar Menu' : 'Criar Novo Menu',
                  style: TextStyle(
                    fontSize: LayoutConstants.fontSizeXLarge,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: LayoutConstants.marginXl),
          
          // Campo Título
          _buildTextField(
            controller: _titleController,
            label: 'Título',
            hint: 'Ex: Apartamentos, Torres, Localização',
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Título é obrigatório';
              }
              return null;
            },
          ),
          
          SizedBox(height: LayoutConstants.marginLg),
          
          // Dropdown Tipo de Menu
          _buildDropdownField(
            label: 'Tipo de Menu',
            value: _selectedMenuType,
            items: _menuTypes,
            onChanged: (value) => setState(() => _selectedMenuType = value!),
          ),
          
          SizedBox(height: LayoutConstants.marginLg),
          
          // Dropdown Menu Pai
          _buildParentMenuDropdown(),
          
          SizedBox(height: LayoutConstants.marginLg),
          
          // Seleção de ícones
          _buildIconSelector(),
          
          SizedBox(height: LayoutConstants.marginLg),
          
          // Campo Descrição (opcional)
          _buildTextField(
            controller: _descriptionController,
            label: 'Descrição (opcional)',
            hint: 'Descrição do menu',
            maxLines: 3,
          ),
          
          SizedBox(height: LayoutConstants.marginXl),
          
          // Botões de ação
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                
                SizedBox(width: LayoutConstants.marginMd),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.all(LayoutConstants.paddingMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.isEditing ? 'Salvar' : 'Adicionar',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Campo de texto customizado
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: LayoutConstants.fontSizeMedium,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
            ),
            children: isRequired
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ]
                : null,
          ),
        ),
        
        SizedBox(height: LayoutConstants.marginSm),
        
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            filled: !enabled,
            fillColor: enabled ? null : AppTheme.outline.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: BorderSide(
                color: enabled ? AppTheme.outline : AppTheme.outline.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.outline),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: BorderSide(color: AppTheme.outline.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: EdgeInsets.all(LayoutConstants.paddingMd),
          ),
        ),
      ],
    );
  }

  /// Dropdown customizado
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: LayoutConstants.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
        
        SizedBox(height: LayoutConstants.marginSm),
        
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: EdgeInsets.all(LayoutConstants.paddingMd),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
        ),
      ],
    );
  }

  /// Dropdown para menu pai
  Widget _buildParentMenuDropdown() {
    final navigationItems = ref.watch(navigationItemsProvider);
    
    // Filtrar apenas items que podem ser pais (não incluir o item atual se editando)
    // e que não sejam submenus (para limitar a 1 nível)
    final availableParents = navigationItems.where((item) {
      // Não pode ser pai de si mesmo
      if (widget.isEditing && widget.itemToEdit?.id == item.id) {
        return false;
      }
      
      // Apenas menus de nível raiz podem ser pais (parentId == null)
      // Isso garante que só teremos 1 nível de profundidade
      if (item.parentId != null) {
        return false;
      }
      
      return true;
    }).toList();

    final parentOptions = [
      'Nenhum (menu principal)',
      ...availableParents.map((item) => item.label),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Menu Pai (opcional)',
          style: TextStyle(
            fontSize: LayoutConstants.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
        
        SizedBox(height: LayoutConstants.marginSm),
        
        DropdownButtonFormField<String>(
          value: _selectedParentId == null 
              ? 'Nenhum (menu principal)'
              : availableParents.where((item) => item.id == _selectedParentId).isNotEmpty
                  ? availableParents.firstWhere((item) => item.id == _selectedParentId).label
                  : 'Nenhum (menu principal)',
          onChanged: (value) {
            setState(() {
              if (value == 'Nenhum (menu principal)') {
                _selectedParentId = null;
              } else {
                final parentMatches = availableParents.where((item) => item.label == value);
                if (parentMatches.isNotEmpty) {
                  final parent = parentMatches.first;
                  
                  // Verificação adicional de segurança
                  if (parent.parentId != null) {
                    SnackbarNotification.showWarning(
                      'Não é possível criar submenus com mais de 1 nível de profundidade'
                    );
                    _selectedParentId = null;
                  } else {
                    _selectedParentId = parent.id;
                  }
                } else {
                  _selectedParentId = null;
                }
              }
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: EdgeInsets.all(LayoutConstants.paddingMd),
          ),
          items: parentOptions.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          )).toList(),
        ),
      ],
    );
  }

  /// Seletor de ícones
  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ícones',
          style: TextStyle(
            fontSize: LayoutConstants.fontSizeMedium,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurface,
          ),
        ),
        
        SizedBox(height: LayoutConstants.marginSm),
        
        // Preview dos ícones selecionados
        Container(
          padding: EdgeInsets.all(LayoutConstants.paddingMd),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.outline),
            borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
          ),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: LayoutConstants.marginSm,
                  children: [
                    Text(
                      'Selecionados: ',
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeSmall,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Icon(_selectedIcon, size: LayoutConstants.iconMedium),
                    Icon(_selectedSelectedIcon, size: LayoutConstants.iconMedium, color: AppTheme.primaryColor),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showIconPicker(context),
                child: const Text('Alterar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Switch row customizado

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

  /// Abre picker de ícones
  void _showIconPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Ícones'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: GridView.builder(
            padding: EdgeInsets.all(LayoutConstants.paddingMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _availableIcons.length ~/ 2,
            itemBuilder: (context, index) {
              final normalIcon = _availableIcons[index * 2];
              final selectedIcon = _availableIcons[index * 2 + 1];
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIcon = normalIcon;
                    _selectedSelectedIcon = selectedIcon;
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.outline),
                    borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
                    color: (_selectedIcon == normalIcon) 
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        normalIcon, 
                        size: 24,
                        color: (_selectedIcon == normalIcon) 
                            ? AppTheme.primaryColor 
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        selectedIcon, 
                        size: 14, 
                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Handler para salvar o menu
  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final navigationNotifier = ref.read(navigationItemsProvider.notifier);
      final allItems = ref.read(navigationItemsProvider);
      
      // Gerar ID único se criando novo
      final itemId = widget.isEditing 
          ? widget.itemToEdit!.id
          : 'menu_${DateTime.now().millisecondsSinceEpoch}';
      
      // Calcular order baseado na posição atual
      final maxOrder = allItems.isEmpty ? 0 : allItems.map((item) => item.order).reduce((a, b) => a > b ? a : b);
      final newOrder = widget.isEditing ? widget.itemToEdit!.order : maxOrder + 1;
      
      // Gerar rota única evitando duplicatas
      final route = widget.isProtectedRoute 
          ? widget.itemToEdit!.route 
          : _generateRoute(
              _titleController.text.trim(), 
              allItems,
              currentItemId: widget.isEditing ? widget.itemToEdit!.id : null,
            );
      
      // Verificar se a rota foi modificada para evitar duplicata
      final baseRoute = _generateBaseRoute(_titleController.text.trim());
      final routeWasModified = route != baseRoute;

      final newItem = NavigationItem(
        id: itemId,
        label: _titleController.text.trim(),
        icon: _selectedIcon,
        selectedIcon: _selectedSelectedIcon,
        route: route,
        order: newOrder,
        parentId: _selectedParentId, // Incluir ID do menu pai
        menuType: _selectedMenuType, // Tipo de apresentação do menu
        isVisible: true, // Sempre visível
        isEnabled: true, // Sempre habilitado
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );
      
      if (widget.isEditing) {
        navigationNotifier.updateNavigationItem(newItem);
        if (routeWasModified && !widget.isProtectedRoute) {
          SnackbarNotification.showInfo('Menu atualizado! Rota ajustada para evitar duplicata: $route');
        } else {
          SnackbarNotification.showSuccess('Menu atualizado com sucesso!');
        }
      } else {
        navigationNotifier.addNavigationItem(newItem);
        if (routeWasModified) {
          SnackbarNotification.showInfo('Menu criado! Rota ajustada para evitar duplicata: $route');
        } else {
          SnackbarNotification.showSuccess('Menu criado com sucesso!');
        }
      }
      
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      SnackbarNotification.showError('Erro ao salvar menu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

}