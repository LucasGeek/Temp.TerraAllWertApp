import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';
import '../atoms/primary_button.dart';
import 'menu_crud_dialog.dart';

/// Widget que exibe instruções para configurar o primeiro menu
/// Aparece quando não há menus de navegação configurados
class FirstMenuInstruction extends ConsumerWidget {
  const FirstMenuInstruction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: context.responsive<double>(
            xs: double.infinity,
            sm: 500,
            md: 600,
            lg: 700,
            xl: 800,
            xxl: 900,
          ),
        ),
        margin: EdgeInsets.all(LayoutConstants.paddingLg),
        padding: EdgeInsets.all(context.responsive<double>(
          xs: LayoutConstants.paddingMd,
          md: LayoutConstants.paddingLg,
          lg: LayoutConstants.paddingXl,
        )),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: LayoutConstants.shadowBlurLarge,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícone principal
            Container(
              width: context.responsive<double>(
                xs: 80,
                md: 100,
                lg: 120,
              ),
              height: context.responsive<double>(
                xs: 80,
                md: 100,
                lg: 120,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: context.responsive<double>(
                  xs: 40,
                  md: 50,
                  lg: 60,
                ),
                color: AppTheme.primaryColor,
              ),
            ),

            SizedBox(height: LayoutConstants.marginLg),

            // Título principal
            Text(
              'Bem-vindo ao Terra Allwert',
              style: TextStyle(
                fontSize: context.responsive<double>(
                  xs: LayoutConstants.fontSizeXLarge,
                  md: LayoutConstants.fontSizeXXLarge,
                  lg: 28,
                ),
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: LayoutConstants.marginMd),

            // Subtítulo
            Text(
              'Configure seu primeiro menu de navegação',
              style: TextStyle(
                fontSize: context.responsive<double>(
                  xs: LayoutConstants.fontSizeMedium,
                  md: LayoutConstants.fontSizeLarge,
                  lg: LayoutConstants.fontSizeXLarge,
                ),
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: LayoutConstants.marginLg),

            // Descrição
            Text(
              'Para começar a usar o sistema, você precisa configurar pelo menos um menu de navegação. '
              'Isso permitirá que você acesse diferentes seções do empreendimento.',
              style: TextStyle(
                fontSize: context.responsive<double>(
                  xs: LayoutConstants.fontSizeSmall,
                  md: LayoutConstants.fontSizeMedium,
                ),
                color: AppTheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: LayoutConstants.marginXl),

            // Lista de instruções
            _buildInstructionsList(context),

            SizedBox(height: LayoutConstants.marginXl),

            // Botão principal
            SizedBox(
              width: context.responsive<double>(
                xs: double.infinity,
                md: 250,
              ),
              child: AppButton.primary(
                onPressed: () => _showMenuCreationDialog(context),
                text: 'Criar Primeiro Menu',
                icon: Icons.add,
                isFullWidth: context.isMobile,
              ),
            ),

            SizedBox(height: LayoutConstants.marginMd),

            // Texto de ajuda
            Text(
              'Você pode adicionar mais menus a qualquer momento',
              style: TextStyle(
                fontSize: LayoutConstants.fontSizeSmall,
                color: AppTheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsList(BuildContext context) {
    final instructions = [
      {
        'icon': Icons.apartment,
        'title': 'Torres e Blocos',
        'description': 'Configure menus para diferentes torres ou blocos do empreendimento',
      },
      {
        'icon': Icons.photo_library,
        'title': 'Galerias de Imagens',
        'description': 'Organize fotos e vídeos do empreendimento por categoria',
      },
      {
        'icon': Icons.map,
        'title': 'Mapas e Plantas',
        'description': 'Adicione plantas baixas e mapas interativos',
      },
      {
        'icon': Icons.info,
        'title': 'Informações',
        'description': 'Crie seções informativas sobre o projeto',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O que você pode configurar:',
          style: TextStyle(
            fontSize: context.responsive<double>(
              xs: LayoutConstants.fontSizeMedium,
              md: LayoutConstants.fontSizeLarge,
            ),
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        SizedBox(height: LayoutConstants.marginMd),
        
        ...instructions.map((instruction) => Padding(
          padding: EdgeInsets.only(bottom: LayoutConstants.marginSm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  instruction['icon'] as IconData,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: LayoutConstants.marginSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instruction['title'] as String,
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeMedium,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      instruction['description'] as String,
                      style: TextStyle(
                        fontSize: LayoutConstants.fontSizeSmall,
                        color: AppTheme.onSurface.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _showMenuCreationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Não permite fechar sem criar um menu
      builder: (context) => const MenuCrudDialog(),
    );
  }
}