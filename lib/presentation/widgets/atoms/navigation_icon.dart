import 'package:flutter/material.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';

/// Atom: Ícone de navegação seguindo SOLID principles
/// Single Responsibility: Apenas renderizar ícone com estados
/// Open/Closed: Extensível via factory methods e variantes
class AppNavigationIcon extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final bool isSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double? size;
  final NavigationIconVariant variant;
  
  const AppNavigationIcon({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.isSelected,
    this.selectedColor,
    this.unselectedColor,
    this.size,
    this.variant = NavigationIconVariant.standard,
  });

  /// Factory para ícone padrão de navegação
  factory AppNavigationIcon.standard({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    required bool isSelected,
    double? size,
  }) => AppNavigationIcon(
    key: key,
    icon: icon,
    selectedIcon: selectedIcon,
    isSelected: isSelected,
    size: size,
    variant: NavigationIconVariant.standard,
  );

  /// Factory para ícone de sidebar
  factory AppNavigationIcon.sidebar({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    required bool isSelected,
    double? size,
  }) => AppNavigationIcon(
    key: key,
    icon: icon,
    selectedIcon: selectedIcon,
    isSelected: isSelected,
    size: size,
    variant: NavigationIconVariant.sidebar,
  );

  /// Factory para ícone de bottom navigation
  factory AppNavigationIcon.bottomNav({
    Key? key,
    required IconData icon,
    IconData? selectedIcon,
    required bool isSelected,
    double? size,
  }) => AppNavigationIcon(
    key: key,
    icon: icon,
    selectedIcon: selectedIcon,
    isSelected: isSelected,
    size: size,
    variant: NavigationIconVariant.bottomNav,
  );

  @override
  Widget build(BuildContext context) {
    return Icon(
      _getEffectiveIcon(),
      color: _getEffectiveColor(),
      size: size ?? _getDefaultSize(),
    );
  }
  
  IconData _getEffectiveIcon() {
    return isSelected ? (selectedIcon ?? icon) : icon;
  }
  
  Color _getEffectiveColor() {
    switch (variant) {
      case NavigationIconVariant.standard:
        return isSelected 
            ? (selectedColor ?? AppTheme.onPrimary)
            : (unselectedColor ?? AppTheme.onPrimary.withValues(alpha: 0.7));
      case NavigationIconVariant.sidebar:
        return isSelected 
            ? (selectedColor ?? AppTheme.primaryColor)
            : (unselectedColor ?? AppTheme.textSecondary);
      case NavigationIconVariant.bottomNav:
        return isSelected 
            ? (selectedColor ?? AppTheme.primaryColor)
            : (unselectedColor ?? AppTheme.textHint);
    }
  }
  
  double _getDefaultSize() {
    switch (variant) {
      case NavigationIconVariant.standard:
        return LayoutConstants.iconMedium;
      case NavigationIconVariant.sidebar:
        return LayoutConstants.iconLarge;
      case NavigationIconVariant.bottomNav:
        return LayoutConstants.iconMedium;
    }
  }
}

/// Enum para variantes do ícone - Open/Closed Principle
enum NavigationIconVariant {
  standard,
  sidebar,
  bottomNav,
}

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppNavigationIcon ao invés de NavigationIcon')
typedef NavigationIcon = AppNavigationIcon;