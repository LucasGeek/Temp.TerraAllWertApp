import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/entities/menu.dart';
import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';
import '../../../../layout/widgets/atoms/primary_button.dart';

/// Organism: Dialog para criação de novo menu
class CreateMenuDialog extends ConsumerStatefulWidget {
  const CreateMenuDialog({super.key});

  @override
  ConsumerState<CreateMenuDialog> createState() => _CreateMenuDialogState();
}

class _CreateMenuDialogState extends ConsumerState<CreateMenuDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ScreenType _selectedScreenType = ScreenType.carousel;
  bool _isVisible = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
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
            Flexible(
              child: SingleChildScrollView(
                child: _buildForm(context),
              ),
            ),
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
              onChanged: (value) => _generateSlug(value),
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
            
            // Slug (gerado automaticamente)
            _buildTextField(
              controller: _slugController,
              label: 'Slug',
              hint: 'Gerado automaticamente do título',
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Slug é obrigatório';
                }
                if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value.trim())) {
                  return 'Slug deve conter apenas letras minúsculas, números e hífens';
                }
                return null;
              },
            ),
            
            SizedBox(height: LayoutConstants.marginMd),
            
            // Descrição (opcional)
            _buildTextField(
              controller: _descriptionController,
              label: 'Descrição',
              hint: 'Descrição opcional do menu',
              maxLines: 3,
            ),
            
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
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

  Widget _buildVisibilitySwitch() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visibilidade',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: LayoutConstants.marginXs),
              Text(
                'Controla se o menu aparecerá na navegação',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
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
        border: Border(
          top: BorderSide(color: AppTheme.outline.withValues(alpha: 0.3)),
        ),
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

  String _getScreenTypeLabel(ScreenType type) {
    switch (type) {
      case ScreenType.carousel:
        return 'Carrossel';
      case ScreenType.pin:
        return 'Pins no Mapa';
      case ScreenType.floorplan:
        return 'Plantas Baixas';
    }
  }

  String _getScreenTypeDescription(ScreenType type) {
    switch (type) {
      case ScreenType.carousel:
        return 'Apresentação em carrossel de imagens';
      case ScreenType.pin:
        return 'Pontos interativos em mapas ou imagens';
      case ScreenType.floorplan:
        return 'Visualização de plantas e layouts';
    }
  }

  void _generateSlug(String title) {
    if (title.isNotEmpty) {
      final slug = title
          .toLowerCase()
          .replaceAll(RegExp(r'[àáâãäå]'), 'a')
          .replaceAll(RegExp(r'[èéêë]'), 'e')
          .replaceAll(RegExp(r'[ìíîï]'), 'i')
          .replaceAll(RegExp(r'[òóôõö]'), 'o')
          .replaceAll(RegExp(r'[ùúûü]'), 'u')
          .replaceAll('ç', 'c')
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      
      _slugController.text = slug;
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
      // TODO: Implementar usecase provider e criar menu
      await Future.delayed(const Duration(seconds: 1)); // Simulação
      
      if (mounted) {
        Navigator.of(context).pop(true); // Retorna true indicando sucesso
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
          SnackBar(
            content: Text('Erro ao criar menu: $e'),
            backgroundColor: Colors.red,
          ),
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