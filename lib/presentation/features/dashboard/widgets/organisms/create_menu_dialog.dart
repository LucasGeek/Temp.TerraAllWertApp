import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/entities/menu.dart';
import '../../../../../domain/usecases/menu/create_menu_usecase.dart';
import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';
import '../../../../layout/widgets/atoms/primary_button.dart';
import '../../../../providers/menu_provider.dart';

/// Organism: Dialog para criação de novo menu
class CreateMenuDialog extends ConsumerStatefulWidget {
  const CreateMenuDialog({super.key});

  @override
  ConsumerState<CreateMenuDialog> createState() => _CreateMenuDialogState();
}

class _CreateMenuDialogState extends ConsumerState<CreateMenuDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  ScreenType _selectedScreenType = ScreenType.carousel;
  MenuType _selectedMenuType = MenuType.standard;
  bool _isVisible = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      child: Container(
        width: isDesktop ? 500 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: isDesktop ? 500 : MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(child: SingleChildScrollView(child: _buildForm(context))),
            _buildActions(context),
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
            Icons.add_circle_outline,
            color: AppTheme.onPrimary,
            size: LayoutConstants.iconLarge,
          ),
          SizedBox(width: LayoutConstants.marginSm),
          Expanded(
            child: Text(
              'Criar Novo Menu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppTheme.onPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título do Menu
            _buildTextField(
              controller: _titleController,
              label: 'Título do Menu',
              hint: 'Digite o título do menu',
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Título é obrigatório';
                }
                if (value.trim().length < 3) {
                  return 'Título deve ter pelo menos 3 caracteres';
                }
                return null;
              },
            ),

            SizedBox(height: LayoutConstants.marginMd),

            // Tipo de Menu
            _buildMenuTypeDropdown(),

            SizedBox(height: LayoutConstants.marginMd),

            // Tipo de Tela
            _buildScreenTypeSelector(),

            SizedBox(height: LayoutConstants.marginMd),

            // Visibilidade
            _buildVisibilitySwitch(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: LayoutConstants.marginXs),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: BorderSide(color: AppTheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.all(LayoutConstants.paddingMd),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Tela *',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        SizedBox(height: LayoutConstants.marginSm),
        ...ScreenType.values.map((type) {
          return RadioListTile<ScreenType>(
            title: Text(_getScreenTypeLabel(type)),
            subtitle: Text(_getScreenTypeDescription(type)),
            value: type,
            groupValue: _selectedScreenType,
            onChanged: (ScreenType? value) {
              if (value != null) {
                setState(() {
                  _selectedScreenType = value;
                });
              }
            },
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildMenuTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Tipo de Menu',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        SizedBox(height: LayoutConstants.marginXs),
        DropdownButtonFormField<MenuType>(
          value: _selectedMenuType,
          decoration: InputDecoration(
            hintText: 'Selecione o tipo de menu',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: BorderSide(color: AppTheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: EdgeInsets.all(LayoutConstants.paddingMd),
          ),
          items: MenuType.values.map((MenuType type) {
            return DropdownMenuItem<MenuType>(value: type, child: Text(_getMenuTypeLabel(type)));
          }).toList(),
          onChanged: (MenuType? value) {
            if (value != null) {
              setState(() {
                _selectedMenuType = value;
              });
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Tipo de menu é obrigatório';
            }
            return null;
          },
        ),
        if (_selectedMenuType == MenuType.submenu)
          Padding(
            padding: EdgeInsets.only(top: LayoutConstants.marginXs),
            child: Text(
              'Submenus são organizados dentro de menus principais',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _buildVisibilitySwitch() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visibilidade',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: LayoutConstants.marginXs),
              Text(
                'Controla se o menu aparecerá na navegação',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: _isVisible,
          onChanged: (bool value) {
            setState(() {
              _isVisible = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingLg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.outline.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton.secondary(
              text: 'Cancelar',
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: LayoutConstants.marginMd),
          Expanded(
            child: AppButton.primary(
              text: 'Criar Menu',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _handleCreateMenu,
            ),
          ),
        ],
      ),
    );
  }

  String _getMenuTypeLabel(MenuType type) {
    switch (type) {
      case MenuType.standard:
        return 'Menu Principal';
      case MenuType.submenu:
        return 'Submenu';
    }
  }

  String _getScreenTypeLabel(ScreenType type) {
    switch (type) {
      case ScreenType.carousel:
        return 'Carrossel';
      case ScreenType.pin:
        return 'Pins';
      case ScreenType.floorplan:
        return 'Pavimentação';
    }
  }

  String _getScreenTypeDescription(ScreenType type) {
    switch (type) {
      case ScreenType.carousel:
        return 'Apresentação em carrossel de imagens';
      case ScreenType.pin:
        return 'Pontos interativos na imagem';
      case ScreenType.floorplan:
        return 'Visualização de plantas e layouts';
    }
  }

  Future<void> _handleCreateMenu() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Criar slug a partir do título
      final slug = _titleController.text.trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      
      // Criar parâmetros para o usecase
      final params = CreateMenuParams(
        title: _titleController.text.trim(),
        slug: slug,
        screenType: _selectedScreenType,
        menuType: _selectedMenuType,
        position: 0, // TODO: calcular próxima posição disponível
        enterpriseLocalId: 'default-enterprise', // TODO: pegar do usuário logado
        isVisible: _isVisible,
      );
      
      // Executar usecase de criação
      final createMenuUseCase = ref.read(createMenuUseCaseProvider);
      final createdMenu = await createMenuUseCase(params);
      
      // Recarregar menus após criação
      await ref.read(menuProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop(true); // Retorna true indicando sucesso
        
        // Navegar automaticamente para o menu criado usando rota dinâmica
        final routeSlug = createdMenu.title.toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '');
        context.go('/dynamic/$routeSlug?title=${Uri.encodeComponent(createdMenu.title)}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu "${_titleController.text}" criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar menu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
