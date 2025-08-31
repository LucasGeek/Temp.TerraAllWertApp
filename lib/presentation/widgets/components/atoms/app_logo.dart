import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';

class AppLogo extends StatelessWidget {
  final double? size;
  final Color? backgroundColor;
  final Color? iconColor;
  
  const AppLogo({
    super.key,
    this.size,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? LayoutConstants.iconXLarge,
      height: size ?? LayoutConstants.iconXLarge,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.business,
        color: iconColor ?? AppTheme.primaryColor,
        size: (size ?? LayoutConstants.iconXLarge) * 0.6,
      ),
    );
  }
}