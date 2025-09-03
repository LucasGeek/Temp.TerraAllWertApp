import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/entities/menu.dart';
import '../../../../../domain/usecases/menu/create_menu_usecase.dart';
import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/widgets/atoms/primary_button.dart';
import '../../../../layout/widgets/organisms/app_dialog.dart';
import '../../../../providers/menu_provider.dart';
import '../../../../utils/notification/snackbar_notification.dart';

/// Organism: Dialog para criação de novo menu usando AppDialog
class CreateMenuDialog {
  /// Método estático para exibir o dialog usando AppDialog com footer
  static Future<bool?> show(BuildContext context) {
    return AppDialog.show<bool>(
      context: context,
      title: 'Criar Novo Menu',
      titleIcon: Icons.add_circle_outline,
      content: const _DialogContent(),
      showCloseButton: true,
      isDismissible: false, // Previne fechar sem salvar
      maxHeight: MediaQuery.of(context).size.height * 0.85, // Garante espaço para scroll
    );
  }
}

/// Conteúdo separado do dialog para melhor organização
class _DialogContent extends ConsumerStatefulWidget {
  const _DialogContent();

  @override
  ConsumerState<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends ConsumerState<_DialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  ScreenType _selectedScreenType = ScreenType.carousel;
  MenuType _selectedMenuType = MenuType.standard;
  final List<String> _selectedSubmenus = []; // IDs dos submenus vinculados
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Formulário com scroll automático
        Flexible(child: SingleChildScrollView(child: _buildForm(context))),
        // Footer com botões
        _buildFooter(context),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: LayoutConstants.paddingMd),
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
              hint: 'Ex: Dashboard, Relatórios, Configurações',
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

            SizedBox(height: LayoutConstants.marginLg),

            // Tipo de Menu
            _buildMenuTypeDropdown(),

            // Tipo de Tela (apenas para Menu Principal)
            if (_selectedMenuType == MenuType.standard) ...[
              SizedBox(height: LayoutConstants.marginLg),
              _buildScreenTypeSelector(),
            ],

            // Seleção de Submenus (apenas para Menu Principal)
            if (_selectedMenuType == MenuType.standard) ...[
              SizedBox(height: LayoutConstants.marginLg),
              _buildSubmenuSelector(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.outline.withValues(alpha: 0.2), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton.secondary(
              text: 'Cancelar',
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTheme.errorColor),
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
              borderSide: BorderSide(color: AppTheme.errorColor),
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
        RichText(
          text: TextSpan(
            text: 'Tipo de Tela',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ],
          ),
        ),
        SizedBox(height: LayoutConstants.marginSm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
          ),
          child: Column(
            children: ScreenType.values.map((type) {
              final isLast = type == ScreenType.values.last;
              return Column(
                children: [
                  RadioListTile<ScreenType>(
                    title: Text(
                      _getScreenTypeLabel(type),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _getScreenTypeDescription(type),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                    ),
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
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: LayoutConstants.paddingMd,
                      vertical: LayoutConstants.paddingXs,
                    ),
                    dense: true,
                  ),
                  if (!isLast) Divider(height: 1, color: AppTheme.outline.withValues(alpha: 0.2)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmenuSelector() {
    // Obter lista de submenus existentes
    final menuState = ref.watch(menuProvider);
    final availableSubmenus = menuState.menus
        .where((menu) => menu.menuType == MenuType.submenu)
        .toList();

    if (availableSubmenus.isEmpty) {
      return Container(
        padding: EdgeInsets.all(LayoutConstants.paddingMd),
        decoration: BoxDecoration(
          color: AppTheme.infoColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
          border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: AppTheme.infoColor),
            SizedBox(width: LayoutConstants.marginXs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhum submenu disponível',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: LayoutConstants.marginXs),
                  Text(
                    'Crie primeiro alguns submenus para poder vinculá-los a este menu principal.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submenus Vinculados (Opcional)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: LayoutConstants.marginXs),
        Text(
          'Selecione os submenus que aparecerão dentro deste menu principal',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        SizedBox(height: LayoutConstants.marginSm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
          ),
          child: Column(
            children: availableSubmenus.map((submenu) {
              final isSelected = _selectedSubmenus.contains(submenu.localId);
              final isLast = submenu == availableSubmenus.last;

              return Column(
                children: [
                  CheckboxListTile(
                    title: Text(
                      submenu.title,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Submenu • ${_getScreenTypeLabel(submenu.screenType)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSubmenus.add(submenu.localId);
                        } else {
                          _selectedSubmenus.remove(submenu.localId);
                        }
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: LayoutConstants.paddingMd,
                      vertical: LayoutConstants.paddingXs,
                    ),
                    dense: true,
                  ),
                  if (!isLast) Divider(height: 1, color: AppTheme.outline.withValues(alpha: 0.2)),
                ],
              );
            }).toList(),
          ),
        ),
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppTheme.errorColor),
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
          Container(
            margin: EdgeInsets.only(top: LayoutConstants.marginSm),
            padding: EdgeInsets.all(LayoutConstants.paddingMd),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.infoColor),
                SizedBox(width: LayoutConstants.marginXs),
                Expanded(
                  child: Text(
                    'Submenus são organizados dentro de menus principais',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
      ],
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
      final slug = _titleController.text
          .trim()
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
        isVisible: true, // Sempre visível por padrão
      );

      // Executar usecase de criação
      final createMenuUseCase = ref.read(createMenuUseCaseProvider);
      final createdMenu = await createMenuUseCase(params);

      // Recarregar menus após criação
      await ref.read(menuProvider.notifier).refresh();

      if (mounted) {
        // Fechar dialog com sucesso
        Navigator.of(context).pop(true);

        // Navegar automaticamente para o menu criado
        final routeSlug = createdMenu.title
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '');
        context.go('/dynamic/$routeSlug?title=${Uri.encodeComponent(createdMenu.title)}');

        // Mostrar notificação de sucesso
        SnackbarNotification.showSuccess('Menu "${_titleController.text}" criado com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarNotification.showError('Erro ao criar menu: $e');
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
