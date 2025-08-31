import 'package:flutter/material.dart';
import '../../../design_system/layout_constants.dart';
import '../../../responsive/breakpoints.dart';

class ResponsiveText extends StatelessWidget {
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
  final FontWeight? fontWeight;
  final Color? color;
  
  const ResponsiveText(
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
    this.fontWeight,
    this.color,
  });

  const ResponsiveText.title(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
  }) : xsFontSize = LayoutConstants.fontSizeLarge,
       smFontSize = LayoutConstants.fontSizeXLarge,
       mdFontSize = LayoutConstants.fontSizeXXLarge,
       lgFontSize = LayoutConstants.fontSizeTitle,
       xlFontSize = LayoutConstants.fontSizeHeading,
       fontWeight = FontWeight.bold;

  const ResponsiveText.body(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
  }) : xsFontSize = LayoutConstants.fontSizeSmall,
       smFontSize = LayoutConstants.fontSizeMedium,
       mdFontSize = LayoutConstants.fontSizeLarge,
       lgFontSize = LayoutConstants.fontSizeXLarge,
       xlFontSize = LayoutConstants.fontSizeXXLarge,
       fontWeight = FontWeight.normal;

  @override
  Widget build(BuildContext context) {
    final responsiveFontSize = context.responsive<double>(
      xs: xsFontSize ?? LayoutConstants.fontSizeMedium,
      sm: smFontSize,
      md: mdFontSize,
      lg: lgFontSize,
      xl: xlFontSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: responsiveFontSize,
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}