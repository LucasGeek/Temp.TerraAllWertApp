import 'package:flutter/material.dart';

import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';

/// Organism: Estado vazio do dashboard quando não há menus
class EmptyDashboardState extends StatelessWidget {
  const EmptyDashboardState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

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
        padding: EdgeInsets.all(
          context.responsive<double>(
            xs: LayoutConstants.paddingMd,
            md: LayoutConstants.paddingLg,
            lg: LayoutConstants.paddingXl,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone ilustrativo
            Container(
              padding: EdgeInsets.all(
                isDesktop ? LayoutConstants.paddingXxl : LayoutConstants.paddingLg,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(LayoutConstants.radiusLarge),
                border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.2), width: 2),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: isDesktop ? 72 : 56,
                color: AppTheme.primaryColor,
              ),
            ),

            SizedBox(height: isDesktop ? 32 : 24),

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

        ...instructions.map(
          (instruction) => Padding(
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
          ),
        ),
      ],
    );
  }
}
