import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';
import '../atoms/navigation_icon.dart';
import '../atoms/responsive_text.dart';

class NavigationItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;
  
  const NavigationItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: context.responsive<double>(
          xs: LayoutConstants.marginXs,
          md: LayoutConstants.marginSm,
          lg: LayoutConstants.marginMd,
        ),
        vertical: LayoutConstants.strokeMedium,
      ),
      child: ListTile(
        leading: NavigationIcon(
          icon: icon,
          selectedIcon: selectedIcon,
          isSelected: isSelected,
        ),
        title: ResponsiveText.body(
          label,
          color: AppTheme.onPrimary, // Sempre branco sobre fundo verde escuro
        ),
        selected: isSelected,
        selectedTileColor: isSelected 
            ? Colors.white.withValues(alpha: 0.15) // Fundo translúcido branco quando ativo
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LayoutConstants.radiusMedium),
        ),
        onTap: onTap,
      ),
    );
  }
}