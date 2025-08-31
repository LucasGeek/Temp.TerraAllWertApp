import 'package:flutter/material.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';

/// Atom: Texto responsivo seguindo SOLID principles
/// Single Responsibility: Apenas renderizar texto responsivo
/// Open/Closed: Extensível via factory methods e variáveis de tipo
class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? xsFontSize;
  final double? smFontSize;
  final double? mdFontSize;
  final double? lgFontSize;
  final double? xlFontSize;
  final double? xxlFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextVariant variant;
  final bool isSelectable;
  
  const AppText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.xsFontSize,
    this.smFontSize,
    this.mdFontSize,
    this.lgFontSize,
    this.xlFontSize,
    this.xxlFontSize,
    this.fontWeight,
    this.color,
    this.variant = TextVariant.body,
    this.isSelectable = false,
  });

  /// Factory para títulos principais
  factory AppText.heading(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    Color? color,
    bool isSelectable = false,
  }) => AppText(
    text,
    key: key,
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    xsFontSize: LayoutConstants.fontSizeXLarge,
    smFontSize: LayoutConstants.fontSizeXXLarge,
    mdFontSize: LayoutConstants.fontSizeTitle,
    lgFontSize: LayoutConstants.fontSizeHeading,
    xlFontSize: LayoutConstants.fontSizeHeading * 1.2,
    xxlFontSize: LayoutConstants.fontSizeHeading * 1.4,
    fontWeight: FontWeight.bold,
    color: color,
    variant: TextVariant.heading,
    isSelectable: isSelectable,
  );

  /// Factory para títulos secundários
  factory AppText.title(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    Color? color,
    bool isSelectable = false,
  }) => AppText(
    text,
    key: key,
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    xsFontSize: LayoutConstants.fontSizeLarge,
    smFontSize: LayoutConstants.fontSizeXLarge,
    mdFontSize: LayoutConstants.fontSizeXXLarge,
    lgFontSize: LayoutConstants.fontSizeTitle,
    xlFontSize: LayoutConstants.fontSizeTitle * 1.1,
    xxlFontSize: LayoutConstants.fontSizeTitle * 1.2,
    fontWeight: FontWeight.w600,
    color: color,
    variant: TextVariant.title,
    isSelectable: isSelectable,
  );

  /// Factory para texto do corpo
  factory AppText.body(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    Color? color,
    bool isSelectable = false,
  }) => AppText(
    text,
    key: key,
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    xsFontSize: LayoutConstants.fontSizeSmall,
    smFontSize: LayoutConstants.fontSizeMedium,
    mdFontSize: LayoutConstants.fontSizeLarge,
    lgFontSize: LayoutConstants.fontSizeXLarge,
    xlFontSize: LayoutConstants.fontSizeXLarge,
    xxlFontSize: LayoutConstants.fontSizeXXLarge,
    fontWeight: FontWeight.normal,
    color: color,
    variant: TextVariant.body,
    isSelectable: isSelectable,
  );

  /// Factory para texto de caption/legenda
  factory AppText.caption(
    String text, {
    Key? key,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    Color? color,
    bool isSelectable = false,
  }) => AppText(
    text,
    key: key,
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    xsFontSize: LayoutConstants.fontSizeSmall,
    smFontSize: LayoutConstants.fontSizeSmall,
    mdFontSize: LayoutConstants.fontSizeMedium,
    lgFontSize: LayoutConstants.fontSizeMedium,
    xlFontSize: LayoutConstants.fontSizeLarge,
    xxlFontSize: LayoutConstants.fontSizeLarge,
    fontWeight: FontWeight.w400,
    color: color,
    variant: TextVariant.caption,
    isSelectable: isSelectable,
  );

  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = context.responsive<double>(
      xs: xsFontSize ?? _getDefaultFontSize().xs,
      sm: smFontSize ?? _getDefaultFontSize().sm,
      md: mdFontSize ?? _getDefaultFontSize().md,
      lg: lgFontSize ?? _getDefaultFontSize().lg,
      xl: xlFontSize ?? _getDefaultFontSize().xl,
      xxl: xxlFontSize ?? _getDefaultFontSize().xxl,
    );

    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      fontSize: responsiveFontSize,
      fontWeight: fontWeight ?? _getDefaultFontWeight(),
      color: color,
    );

    if (isSelectable) {
      return SelectableText(
        text,
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
  
  _FontSizes _getDefaultFontSize() {
    switch (variant) {
      case TextVariant.heading:
        return _FontSizes(
          xs: LayoutConstants.fontSizeXLarge,
          sm: LayoutConstants.fontSizeXXLarge,
          md: LayoutConstants.fontSizeTitle,
          lg: LayoutConstants.fontSizeHeading,
          xl: LayoutConstants.fontSizeHeading * 1.2,
          xxl: LayoutConstants.fontSizeHeading * 1.4,
        );
      case TextVariant.title:
        return _FontSizes(
          xs: LayoutConstants.fontSizeLarge,
          sm: LayoutConstants.fontSizeXLarge,
          md: LayoutConstants.fontSizeXXLarge,
          lg: LayoutConstants.fontSizeTitle,
          xl: LayoutConstants.fontSizeTitle * 1.1,
          xxl: LayoutConstants.fontSizeTitle * 1.2,
        );
      case TextVariant.body:
        return _FontSizes(
          xs: LayoutConstants.fontSizeSmall,
          sm: LayoutConstants.fontSizeMedium,
          md: LayoutConstants.fontSizeLarge,
          lg: LayoutConstants.fontSizeXLarge,
          xl: LayoutConstants.fontSizeXLarge,
          xxl: LayoutConstants.fontSizeXXLarge,
        );
      case TextVariant.caption:
        return _FontSizes(
          xs: LayoutConstants.fontSizeSmall,
          sm: LayoutConstants.fontSizeSmall,
          md: LayoutConstants.fontSizeMedium,
          lg: LayoutConstants.fontSizeMedium,
          xl: LayoutConstants.fontSizeLarge,
          xxl: LayoutConstants.fontSizeLarge,
        );
    }
  }
  
  FontWeight _getDefaultFontWeight() {
    switch (variant) {
      case TextVariant.heading:
        return FontWeight.bold;
      case TextVariant.title:
        return FontWeight.w600;
      case TextVariant.body:
        return FontWeight.normal;
      case TextVariant.caption:
        return FontWeight.w400;
    }
  }
}

/// Helper class para tamanhos de fonte
class _FontSizes {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  
  const _FontSizes({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });
}

/// Enum para variantes de texto - Open/Closed Principle
enum TextVariant {
  heading,
  title,
  body,
  caption,
}

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppText ao invés de ResponsiveText')
typedef ResponsiveText = AppText;