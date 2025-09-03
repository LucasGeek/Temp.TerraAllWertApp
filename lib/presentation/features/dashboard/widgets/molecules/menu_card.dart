import 'package:flutter/material.dart';

import '../../../../../domain/entities/menu.dart';
import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';

/// Molecule: Card de menu do dashboard
class MenuCard extends StatelessWidget {
  final Menu menu;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.menu,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(LayoutConstants.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Ícone do menu
                  _buildMenuIcon(context),
                  const SizedBox(width: 12),
                  
                  // Título e badge de tipo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildScreenTypeBadge(context),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Descrição (se houver)
              if (menu.description != null && menu.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  menu.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Status indicators
              const SizedBox(height: 8),
              _buildStatusRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;
    
    // Definir ícone baseado no tipo de tela
    switch (menu.screenType) {
      case ScreenType.carousel:
        iconData = Icons.view_carousel;
        iconColor = Colors.blue;
        break;
      case ScreenType.pin:
        iconData = Icons.location_on;
        iconColor = Colors.red;
        break;
      case ScreenType.floorplan:
        iconData = Icons.apartment;
        iconColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
      ),
      child: Icon(
        iconData,
        size: context.responsive<double>(
          xs: 20,
          md: 22,
          lg: 24,
        ),
        color: iconColor,
      ),
    );
  }

  Widget _buildScreenTypeBadge(BuildContext context) {
    String label;
    Color color;
    
    switch (menu.screenType) {
      case ScreenType.carousel:
        label = 'Carrossel';
        color = Colors.blue;
        break;
      case ScreenType.pin:
        label = 'Pins';
        color = Colors.red;
        break;
      case ScreenType.floorplan:
        label = 'Plantas';
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    return Row(
      children: [
        // Status ativo/inativo
        Icon(
          menu.isActive ? Icons.check_circle : Icons.pause_circle,
          size: 16,
          color: menu.isActive ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 4),
        Text(
          menu.isActive ? 'Ativo' : 'Inativo',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: menu.isActive ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const Spacer(),
        
        // Disponibilidade offline
        if (menu.isAvailableOffline) ...[
          Icon(
            Icons.offline_bolt,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}