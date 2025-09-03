import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/layout_constants.dart';
import '../../responsive/breakpoints.dart';

/// Atom: Logo Terra Allwert seguindo SOLID principles
/// Single Responsibility: Apenas renderizar logo da empresa
/// Open/Closed: Extensível via factory methods e variantes
class AppLogo extends StatelessWidget {
  final double? size;
  final bool showText;
  final MainAxisAlignment alignment;
  final LogoVariant variant;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.size,
    this.showText = true,
    this.alignment = MainAxisAlignment.start,
    this.variant = LogoVariant.standard,
    this.primaryColor,
    this.secondaryColor,
    this.textColor,
  });

  /// Factory para logo completo com texto
  factory AppLogo.full({
    Key? key,
    double? size,
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) => AppLogo(
    key: key,
    size: size,
    showText: true,
    alignment: alignment,
    variant: LogoVariant.standard,
  );

  /// Factory para apenas o ícone
  factory AppLogo.iconOnly({
    Key? key,
    double? size,
    MainAxisAlignment alignment = MainAxisAlignment.center,
  }) => AppLogo(
    key: key,
    size: size,
    showText: false,
    alignment: alignment,
    variant: LogoVariant.iconOnly,
  );

  /// Factory para versão compacta (header)
  factory AppLogo.compact({Key? key, MainAxisAlignment alignment = MainAxisAlignment.start}) =>
      AppLogo(
        key: key,
        size: LayoutConstants.iconXLarge,
        showText: true,
        alignment: alignment,
        variant: LogoVariant.compact,
      );

  /// Factory para versão mínima (favicon style)
  factory AppLogo.minimal({Key? key}) => AppLogo(
    key: key,
    size: LayoutConstants.iconLarge,
    showText: false,
    alignment: MainAxisAlignment.center,
    variant: LogoVariant.minimal,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? _getDefaultSize(context);

    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(effectiveSize, effectiveSize),
          painter: _TerraLogoPainter(
            primaryColor: primaryColor ?? AppTheme.primaryColor,
            secondaryColor: secondaryColor ?? AppTheme.primaryLight,
            tertiaryColor: AppTheme.primaryDark,
            variant: variant,
          ),
        ),
        if (showText) ...[
          SizedBox(width: _getTextSpacing(effectiveSize)),
          Text('Terra Allwert', style: _getTextStyle(context, effectiveSize)),
        ],
      ],
    );
  }

  double _getDefaultSize(BuildContext context) {
    switch (variant) {
      case LogoVariant.standard:
        return context.responsive<double>(xs: 28, sm: 32, md: 36, lg: 40, xl: 44);
      case LogoVariant.iconOnly:
        return LayoutConstants.iconXLarge;
      case LogoVariant.compact:
        return LayoutConstants.iconLarge;
      case LogoVariant.minimal:
        return LayoutConstants.iconMedium;
    }
  }

  double _getTextSpacing(double logoSize) {
    if (logoSize <= 24) return 8;
    if (logoSize <= 32) return 12;
    return 16;
  }

  TextStyle _getTextStyle(BuildContext context, double logoSize) {
    final baseStyle = Theme.of(context).textTheme.titleLarge;
    final fontSize = (logoSize * 0.6).clamp(12.0, 24.0);

    return baseStyle?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppTheme.textPrimary,
          letterSpacing: -0.5,
        ) ??
        TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppTheme.textPrimary,
          letterSpacing: -0.5,
        );
  }
}

/// Painter customizado para o logo Terra Allwert
class _TerraLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final LogoVariant variant;

  const _TerraLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.variant,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Face frontal (mais clara)
    paint.color = primaryColor;
    _drawHexagonFace(canvas, paint, center, radius, 0);

    // Face direita (média) - apenas se não for minimal
    if (variant != LogoVariant.minimal) {
      paint.color = secondaryColor;
      _drawHexagonFace(
        canvas,
        paint,
        center + Offset(radius * 0.3, -radius * 0.2),
        radius * 0.8,
        0,
      );
    }

    // Face superior (mais escura) - apenas para versões completas
    if (variant == LogoVariant.standard) {
      paint.color = tertiaryColor;
      _drawHexagonFace(
        canvas,
        paint,
        center + Offset(radius * 0.15, -radius * 0.4),
        radius * 0.9,
        0,
      );
    }

    // Bordas para definição
    paint
      ..style = PaintingStyle.stroke
      ..color = tertiaryColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    _drawHexagonFace(canvas, paint, center, radius, 0);

    if (variant != LogoVariant.minimal) {
      _drawHexagonFace(
        canvas,
        paint,
        center + Offset(radius * 0.3, -radius * 0.2),
        radius * 0.8,
        0,
      );
    }

    if (variant == LogoVariant.standard) {
      _drawHexagonFace(
        canvas,
        paint,
        center + Offset(radius * 0.15, -radius * 0.4),
        radius * 0.9,
        0,
      );
    }
  }

  void _drawHexagonFace(Canvas canvas, Paint paint, Offset center, double radius, double rotation) {
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 + rotation) * (math.pi / 180);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _TerraLogoPainter) return true;
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.tertiaryColor != tertiaryColor ||
        oldDelegate.variant != variant;
  }
}

/// Enum para variantes do logo - Open/Closed Principle
enum LogoVariant {
  standard, // Logo completo com todas as faces
  iconOnly, // Apenas o ícone
  compact, // Versão compacta
  minimal, // Versão mínima (uma face)
}

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppLogo ao invés de TerraLogo')
typedef TerraLogo = AppLogo;
