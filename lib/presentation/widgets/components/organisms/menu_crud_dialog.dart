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

  const MenuCrudDialog({
    super.key,
    this.itemToEdit,
    this.isEditing = false,
  });

  @override
  ConsumerState<MenuCrudDialog> createState() => _MenuCrudDialogState();
}

class _MenuCrudDialogState extends ConsumerState<MenuCrudDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _routeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedMenuType = 'Menu Padrão';
  String? _selectedParentId;
  IconData _selectedIcon = Icons.home_outlined;
  IconData _selectedSelectedIcon = Icons.home;
  bool _isVisible = true;
  bool _isEnabled = true;
  bool _isLoading = false;

  // Tipos de menu baseados no sistema legado
  final List<String> _menuTypes = [
    'Menu Padrão',
    'Menu com Pins', 
    'Menu Pavimento',
  ];

  // Ícones disponíveis
  final Map<String, List<IconData>> _availableIcons = {
    'Geral': [
      Icons.home_outlined, Icons.home,
      Icons.dashboard_outlined, Icons.dashboard,
      Icons.menu_outlined, Icons.menu,
      Icons.settings_outlined, Icons.settings,
    ],
    'Navegação': [
      Icons.explore_outlined, Icons.explore,
      Icons.location_on_outlined, Icons.location_on,
      Icons.map_outlined, Icons.map,
      Icons.directions_outlined, Icons.directions,
    ],
    'Conteúdo': [
      Icons.photo_library_outlined, Icons.photo_library,
      Icons.video_library_outlined, Icons.video_library,
      Icons.article_outlined, Icons.article,
      Icons.description_outlined, Icons.description,
    ],
    'Imóveis': [
      Icons.business_outlined, Icons.business,
      Icons.apartment_outlined, Icons.apartment,
      Icons.house_outlined, Icons.house,
      Icons.architecture_outlined, Icons.architecture,
    ],
  };

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
    _routeController.text = item.route;
    _descriptionController.text = item.description ?? '';
    _selectedIcon = item.icon;
    _selectedSelectedIcon = item.selectedIcon;
    _isVisible = item.isVisible;
    _isEnabled = item.isEnabled;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _routeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
    );
  }

  /// Dialog para desktop/tablet
  Widget _buildDesktopDialog(BuildContext context) {
    return Center(
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
          
          // Campo Rota
          _buildTextField(
            controller: _routeController,
            label: 'Rota',
            hint: 'Ex: /apartamentos, /torres/torre1',
            isRequired: true,
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
          
          SizedBox(height: LayoutConstants.marginLg),
          
          // Switches
          _buildSwitchRow(
            'Visível no menu',
            _isVisible,
            (value) => setState(() => _isVisible = value),
          ),
          
          SizedBox(height: LayoutConstants.marginSm),
          
          _buildSwitchRow(
            'Habilitado',
            _isEnabled,
            (value) => setState(() => _isEnabled = value),
          ),
          
          SizedBox(height: LayoutConstants.marginXl),
          
          // Botões de ação
          SizedBox(
            width: double.infinity,
            child: Row(
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
          decoration: InputDecoration(
            hintText: hint,
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
    final availableParents = navigationItems.where((item) {
      if (widget.isEditing && widget.itemToEdit?.id == item.id) {
        return false; // Não pode ser pai de si mesmo
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
              : availableParents.firstWhere((item) => item.id == _selectedParentId).label,
          onChanged: (value) {
            setState(() {
              if (value == 'Nenhum (menu principal)') {
                _selectedParentId = null;
              } else {
                final parent = availableParents.firstWhere((item) => item.label == value);
                _selectedParentId = parent.id;
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
                child: Row(
                  children: [
                    Text(
                      'Selecionados: ',
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeSmall,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Icon(_selectedIcon, size: LayoutConstants.iconMedium),
                    SizedBox(width: LayoutConstants.marginSm),
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
  Widget _buildSwitchRow(String label, bool value, void Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: LayoutConstants.fontSizeMedium,
            color: AppTheme.onSurface,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
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

  /// Abre picker de ícones
  void _showIconPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Ícones'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: DefaultTabController(
            length: _availableIcons.keys.length,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: _availableIcons.keys.map((category) => Tab(text: category)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: _availableIcons.entries.map((entry) {
                      return GridView.builder(
                        padding: EdgeInsets.all(LayoutConstants.paddingMd),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: entry.value.length ~/ 2,
                        itemBuilder: (context, index) {
                          final normalIcon = entry.value[index * 2];
                          final selectedIcon = entry.value[index * 2 + 1];
                          
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
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(normalIcon, size: 24),
                                  const SizedBox(height: 4),
                                  Icon(selectedIcon, size: 16, color: AppTheme.primaryColor),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
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
      
      final newItem = NavigationItem(
        id: itemId,
        label: _titleController.text.trim(),
        icon: _selectedIcon,
        selectedIcon: _selectedSelectedIcon,
        route: _routeController.text.trim(),
        order: newOrder,
        isVisible: _isVisible,
        isEnabled: _isEnabled,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );
      
      if (widget.isEditing) {
        navigationNotifier.updateNavigationItem(newItem);
        SnackbarNotification.showSuccess('Menu atualizado com sucesso!');
      } else {
        navigationNotifier.addNavigationItem(newItem);
        SnackbarNotification.showSuccess('Menu criado com sucesso!');
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