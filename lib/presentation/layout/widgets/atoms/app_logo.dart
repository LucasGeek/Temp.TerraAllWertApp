import 'package:flutter/material.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';

/// Atom: Logo da aplicação seguindo Single Responsibility Principle
/// Responsável apenas por exibir o logo com configurações visuais
class AppLogo extends StatelessWidget {
  final double? size;
  final Color? backgroundColor;
  final Color? iconColor;
  final LogoVariant variant;
  
  const AppLogo({
    super.key,
    this.size,
    this.backgroundColor,
    this.iconColor,
    this.variant = LogoVariant.circular,
  });

  /// Factory para logo circular padrão
  factory AppLogo.circular({double? size}) => AppLogo(
    size: size,
    variant: LogoVariant.circular,
  );

  /// Factory para logo quadrado
  factory AppLogo.square({double? size}) => AppLogo(
    size: size,
    variant: LogoVariant.square,
  );

  /// Factory para logo pequeno (header)
  factory AppLogo.small() => AppLogo(
    size: LayoutConstants.iconLarge,
    variant: LogoVariant.circular,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? LayoutConstants.iconXLarge;
    
    return Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: _buildDecoration(),
      child: _buildIcon(effectiveSize),
    );
  }

  BoxDecoration _buildDecoration() {
    final bgColor = backgroundColor ?? Colors.white;
    
    return BoxDecoration(
      color: bgColor,
      shape: variant == LogoVariant.circular ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: variant == LogoVariant.square 
          ? BorderRadius.circular(LayoutConstants.radiusMedium)
          : null,
      border: Border.all(
        color: AppTheme.outline.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildIcon(double effectiveSize) {
    return Icon(
      Icons.business,
      color: iconColor ?? AppTheme.primaryColor,
      size: effectiveSize * 0.6,
      semanticLabel: 'Logo Terra Allwert',
    );
  }
}

/// Enum para variantes do logo - Open/Closed Principle
enum LogoVariant {
  circular,
  square,
}