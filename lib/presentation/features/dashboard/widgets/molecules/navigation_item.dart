import 'package:flutter/material.dart';
import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/design_system/layout_constants.dart';
import '../../../../layout/responsive/breakpoints.dart';
import '../../../../layout/widgets/atoms/responsive_text.dart';
import '../atoms/navigation_icon.dart';

/// Molecule: Item de navegação seguindo SOLID principles
/// Single Responsibility: Apenas renderizar item de navegação
/// Open/Closed: Extensível via factory methods e variantes
class AppNavigationItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final NavigationItemVariant variant;
  final bool isSubmenuItem;
  final Color? backgroundColor;
  final Color? textColor;
  final double? iconSize;

  const AppNavigationItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.margin,
    this.padding,
    this.variant = NavigationItemVariant.standard,
    this.isSubmenuItem = false,
    this.backgroundColor,
    this.textColor,
    this.iconSize,
  });

  /// Factory para item padrão de navegação
  factory AppNavigationItem.standard({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    EdgeInsetsGeometry? margin,
  }) => AppNavigationItem(
    key: key,
    icon: icon,
    selectedIcon: selectedIcon,
    label: label,
    isSelected: isSelected,
    onTap: onTap,
    margin: margin,
    variant: NavigationItemVariant.standard,
  );

  /// Factory para item de sidebar
  factory AppNavigationItem.sidebar({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isSubmenuItem = false,
  }) => AppNavigationItem(
    key: key,
    icon: icon,
    selectedIcon: selectedIcon,
    label: label,
    isSelected: isSelected,
    onTap: onTap,
    variant: NavigationItemVariant.sidebar,
    isSubmenuItem: isSubmenuItem,
  );

  /// Factory para item de drawer
  factory AppNavigationItem.drawer({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) => AppNavigationItem(
    key: key,
    icon: icon,
    selectedIcon: selectedIcon,
    label: label,
    isSelected: isSelected,
    onTap: onTap,
    variant: NavigationItemVariant.drawer,
  );

  /// Factory para item compacto
  factory AppNavigationItem.compact({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) => AppNavigationItem(
    key: key,
    icon: icon,
    selectedIcon: selectedIcon,
    label: label,
    isSelected: isSelected,
    onTap: onTap,
    variant: NavigationItemVariant.compact,
  );

  @override
  Widget build(BuildContext context) {
    return Container(margin: margin ?? _getDefaultMargin(context), child: _buildContent(context));
  }

  EdgeInsetsGeometry _getDefaultMargin(BuildContext context) {
    switch (variant) {
      case NavigationItemVariant.standard:
        return EdgeInsets.symmetric(
          horizontal: context.responsive<double>(
            xs: LayoutConstants.marginXs,
            md: LayoutConstants.marginSm,
            lg: LayoutConstants.marginMd,
          ),
          vertical: LayoutConstants.strokeMedium,
        );
      case NavigationItemVariant.sidebar:
      case NavigationItemVariant.drawer:
        return EdgeInsets.symmetric(
          horizontal: isSubmenuItem ? 0 : LayoutConstants.paddingXs,
          vertical: 2,
        );
      case NavigationItemVariant.compact:
        return const EdgeInsets.symmetric(horizontal: 4, vertical: 1);
    }
  }

  Widget _buildContent(BuildContext context) {
    switch (variant) {
      case NavigationItemVariant.standard:
        return _buildStandardItem(context);
      case NavigationItemVariant.sidebar:
      case NavigationItemVariant.drawer:
        return _buildSidebarItem(context);
      case NavigationItemVariant.compact:
        return _buildCompactItem(context);
    }
  }

  Widget _buildStandardItem(BuildContext context) {
    return ListTile(
      leading: AppNavigationIcon.standard(
        icon: icon,
        selectedIcon: selectedIcon,
        isSelected: isSelected,
        size: iconSize,
      ),
      title: AppText.body(label, color: textColor ?? AppTheme.onPrimary),
      selected: isSelected,
      selectedTileColor: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSidebarItem(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (backgroundColor ?? AppTheme.onPrimary.withValues(alpha: 0.12))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        border: isSelected
            ? Border.all(color: AppTheme.onPrimary.withValues(alpha: 0.2), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          isSelected && selectedIcon != null ? selectedIcon! : icon,
          color: isSelected ? AppTheme.onPrimary : AppTheme.onPrimary.withValues(alpha: 0.7),
          size:
              iconSize ?? (isSubmenuItem ? LayoutConstants.iconMedium : LayoutConstants.iconLarge),
        ),
        title: Text(
          label,
          style: TextStyle(
            color:
                textColor ??
                (isSelected ? AppTheme.onPrimary : AppTheme.onPrimary.withValues(alpha: 0.7)),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: isSubmenuItem ? 14 : 16,
          ),
        ),
        onTap: onTap,
        contentPadding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: LayoutConstants.paddingMd,
              vertical: LayoutConstants.paddingXs,
            ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        ),
      ),
    );
  }

  Widget _buildCompactItem(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (backgroundColor ?? AppTheme.primaryColor.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(LayoutConstants.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected && selectedIcon != null ? selectedIcon! : icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: iconSize ?? LayoutConstants.iconSmall,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor ?? (isSelected ? AppTheme.primaryColor : AppTheme.textSecondary),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enum para variantes do item de navegação - Open/Closed Principle
enum NavigationItemVariant { standard, sidebar, drawer, compact }

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppNavigationItem ao invés de NavigationItem')
typedef NavigationItem = AppNavigationItem;

/// Backward compatibility para NavigationMenuItem
@Deprecated('Use AppNavigationItem.sidebar() ao invés de NavigationMenuItem')
typedef NavigationMenuItem = AppNavigationItem;
