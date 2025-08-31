import 'package:flutter/material.dart';
import '../../design_system/app_theme.dart';

/// Atom: Indicador de carregamento simples
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  
  const AppLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.primaryColor,
        ),
      ),
    );
  }
}