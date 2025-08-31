import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';

class NavigationIcon extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final bool isSelected;
  final Color? selectedColor;
  final Color? unselectedColor;
  
  const NavigationIcon({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.isSelected,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      isSelected ? (selectedIcon ?? icon) : icon,
      color: isSelected 
          ? (selectedColor ?? AppTheme.onPrimary) // Branco quando selecionado
          : (unselectedColor ?? AppTheme.onPrimary.withValues(alpha: 0.7)), // Branco com opacity quando não selecionado
    );
  }
}