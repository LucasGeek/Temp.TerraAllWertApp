import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import 'app_dialog.dart';

/// Exemplo de implementação usando o AppDialog
/// Este é um exemplo de como criar um dialog de criação de menu usando o AppDialog padrão
class CreateMenuDialogExample extends ConsumerStatefulWidget {
  const CreateMenuDialogExample({super.key});
  
  /// Método estático para exibir o dialog
  static Future<void> show(BuildContext context) {
    return AppDialog.show(
      context: context,
      title: 'Criar Novo Menu',
      titleIcon: Icons.menu,
      subtitle: Text(
        'Preencha os campos abaixo para criar um novo item de menu',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      content: const CreateMenuDialogExample(),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Lógica de salvamento
            Navigator.of(context).pop();
          },
          child: const Text('Criar Menu'),
        ),
      ],
    );
  }

  @override
  ConsumerState<CreateMenuDialogExample> createState() => _CreateMenuDialogExampleState();
}

class _CreateMenuDialogExampleState extends ConsumerState<CreateMenuDialogExample> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _iconController = TextEditingController();
  final _routeController = TextEditingController();
  String _selectedType = 'page';

  @override
  void dispose() {
    _titleController.dispose();
    _iconController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de título
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Título do Menu',
              hintText: 'Ex: Dashboard',
              prefixIcon: Icon(Icons.text_fields),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, informe o título';
              }
              return null;
            },
          ),
          const SizedBox(height: LayoutConstants.paddingMd),
          
          // Tipo de menu
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Tipo de Menu',
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(value: 'page', child: Text('Página')),
              DropdownMenuItem(value: 'section', child: Text('Seção')),
              DropdownMenuItem(value: 'external', child: Text('Link Externo')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value ?? 'page';
              });
            },
          ),
          const SizedBox(height: LayoutConstants.paddingMd),
          
          // Campo de ícone
          TextFormField(
            controller: _iconController,
            decoration: const InputDecoration(
              labelText: 'Ícone (opcional)',
              hintText: 'Ex: home, dashboard, settings',
              prefixIcon: Icon(Icons.palette),
            ),
          ),
          const SizedBox(height: LayoutConstants.paddingMd),
          
          // Campo de rota
          TextFormField(
            controller: _routeController,
            decoration: const InputDecoration(
              labelText: 'Rota/URL',
              hintText: 'Ex: /dashboard ou https://exemplo.com',
              prefixIcon: Icon(Icons.link),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, informe a rota';
              }
              if (_selectedType == 'external' && !value.startsWith('http')) {
                return 'Links externos devem começar com http:// ou https://';
              }
              if (_selectedType != 'external' && !value.startsWith('/')) {
                return 'Rotas internas devem começar com /';
              }
              return null;
            },
          ),
          const SizedBox(height: LayoutConstants.paddingLg),
          
          // Nota informativa
          Container(
            padding: const EdgeInsets.all(LayoutConstants.paddingMd),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
              border: Border.all(
                color: AppTheme.infoColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: LayoutConstants.marginSm),
                Expanded(
                  child: Text(
                    'O menu será adicionado à navegação principal e ficará disponível para todos os usuários com permissão.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Exemplo de uso dos métodos de conveniência
class DialogExamplesPage extends StatelessWidget {
  const DialogExamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exemplos de Diálogos')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dialog customizado
            ElevatedButton(
              onPressed: () => CreateMenuDialogExample.show(context),
              child: const Text('Criar Menu (Custom Dialog)'),
            ),
            const SizedBox(height: 16),
            
            // Dialog de confirmação
            ElevatedButton(
              onPressed: () async {
                final result = await context.showConfirmDialog(
                  title: 'Excluir Item',
                  message: 'Tem certeza que deseja excluir este item? Esta ação não pode ser desfeita.',
                  icon: Icons.delete_outline,
                  confirmText: 'Excluir',
                  isDangerous: true,
                );
                if (result == true) {
                  // Executar exclusão
                }
              },
              child: const Text('Dialog de Confirmação'),
            ),
            const SizedBox(height: 16),
            
            // Dialog de erro
            ElevatedButton(
              onPressed: () => context.showErrorDialog(
                title: 'Erro ao Salvar',
                message: 'Não foi possível salvar as alterações. Verifique sua conexão e tente novamente.',
              ),
              child: const Text('Dialog de Erro'),
            ),
            const SizedBox(height: 16),
            
            // Dialog de sucesso
            ElevatedButton(
              onPressed: () => context.showSuccessDialog(
                title: 'Salvo com Sucesso',
                message: 'As alterações foram salvas com sucesso!',
              ),
              child: const Text('Dialog de Sucesso'),
            ),
          ],
        ),
      ),
    );
  }
}