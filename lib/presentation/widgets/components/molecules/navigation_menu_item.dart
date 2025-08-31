import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';

/// Item de navegação para menus (renomeado para evitar conflito)
/// Usado em drawer e sidebar de navegação
class NavigationMenuItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NavigationMenuItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isSelected && selectedIcon != null ? selectedIcon! : icon,
        color: isSelected ? AppTheme.onPrimary : AppTheme.onPrimary.withValues(alpha: 0.7),
        size: LayoutConstants.iconLarge,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.onPrimary : AppTheme.onPrimary.withValues(alpha: 0.7),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.onPrimary.withValues(alpha: 0.1),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: LayoutConstants.paddingMd,
        vertical: LayoutConstants.paddingXs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
      ),
    );
  }
}