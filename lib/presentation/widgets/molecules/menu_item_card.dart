import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../../domain/entities/navigation_item.dart';

/// Card para exibir item de menu com ações de editar e excluir
class MenuItemCard extends StatelessWidget {
  final NavigationItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MenuItemCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: LayoutConstants.marginSm),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
          ),
          child: Icon(
            item.icon,
            color: AppTheme.primaryColor,
            size: LayoutConstants.iconMedium,
          ),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: LayoutConstants.fontSizeMedium,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.route,
              style: TextStyle(
                fontSize: LayoutConstants.fontSizeSmall,
                color: AppTheme.textSecondary,
              ),
            ),
            if (item.description != null && item.description!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: LayoutConstants.marginXs),
                child: Text(
                  item.description!,
                  style: TextStyle(
                    fontSize: LayoutConstants.fontSizeSmall,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            SizedBox(height: LayoutConstants.marginXs),
            Row(
              children: [
                _buildStatusChip(
                  label: 'Visível',
                  isActive: item.isVisible,
                  color: Colors.green,
                ),
                SizedBox(width: LayoutConstants.marginXs),
                _buildStatusChip(
                  label: 'Habilitado',
                  isActive: item.isEnabled,
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Icon(
              Icons.drag_indicator,
              color: AppTheme.textSecondary,
              size: LayoutConstants.iconSmall,
            ),
            SizedBox(width: LayoutConstants.marginXs),
            // Edit button
            IconButton(
              icon: Icon(
                Icons.edit,
                size: LayoutConstants.iconSmall,
                color: AppTheme.primaryColor,
              ),
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            // Delete button
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: LayoutConstants.iconSmall,
                color: AppTheme.errorColor,
              ),
              onPressed: onDelete,
              tooltip: 'Excluir',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: LayoutConstants.marginXs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: isActive ? color : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}