import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/entities/menu.dart';
import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';
import '../molecules/menu_card.dart';

/// Organism: Grid de menus do dashboard
class DashboardMenusGrid extends StatelessWidget {
  final List<Menu> menus;

  const DashboardMenusGrid({
    super.key,
    required this.menus,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = context.responsive<int>(
      xs: 1,    // Mobile: 1 coluna
      sm: 2,    // Mobile grande: 2 colunas
      md: 2,    // Tablet: 2 colunas
      lg: 3,    // Desktop: 3 colunas
      xl: 4,    // Desktop grande: 4 colunas
      xxl: 4,   // Desktop muito grande: 4 colunas
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menus Disponíveis',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Chip(
                label: Text('${menus.length}'),
                backgroundColor: AppTheme.primaryLight,
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Grid de menus
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: LayoutConstants.marginMd,
              mainAxisSpacing: LayoutConstants.marginMd,
              childAspectRatio: context.responsive<double>(
                xs: 3.5,  // Mobile: cards mais largos
                sm: 3.0,  // Mobile grande: proporção média
                md: 2.8,  // Tablet: proporção média
                lg: 2.5,  // Desktop: cards mais quadrados
                xl: 2.3,  // Desktop grande: mais quadrados
                xxl: 2.2, // Desktop muito grande: mais quadrados
              ),
            ),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];
              return MenuCard(
                menu: menu,
                onTap: () => _handleMenuTap(context, menu),
              );
            },
          ),
          
          // Footer informativo
          const SizedBox(height: 24),
          _buildFooterInfo(context),
        ],
      ),
    );
  }

  Widget _buildFooterInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(LayoutConstants.paddingMd),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Toque em um menu para navegar para a seção correspondente do sistema.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuTap(BuildContext context, Menu menu) {
    // Navegar baseado no tipo de tela do menu
    switch (menu.screenType) {
      case ScreenType.carousel:
        context.go('/dynamic/${menu.slug}?title=${menu.title}');
        break;
      case ScreenType.pin:
        context.go('/dynamic/${menu.slug}?title=${menu.title}');
        break;
      case ScreenType.floorplan:
        context.go('/dynamic/${menu.slug}?title=${menu.title}');
        break;
    }
  }
}