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
      child: Padding(
        padding: EdgeInsets.all(LayoutConstants.paddingLg),
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

            // Título
            Text(
              'Menus ainda não cadastrados',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isDesktop ? 16 : 12),

            // Descrição
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 500 : double.infinity),
              child: Text(
                'Para começar a usar o sistema, você precisa cadastrar pelo menos um menu. '
                'Os menus permitem organizar e acessar diferentes seções do aplicativo.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: isDesktop ? 32 : 24),
          ],
        ),
      ),
    );
  }
}
