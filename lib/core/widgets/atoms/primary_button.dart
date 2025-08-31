import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Atom: Botão primário seguindo Material Design 2
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets padding;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.secondaryLight,
        disabledForegroundColor: Colors.white,
        elevation: 2, // Sombra nível 2dp
        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
        padding: padding,
        minimumSize: Size(
          isFullWidth ? double.infinity : 120,
          48, // Altura mínima de toque (Material Guidelines)
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // ~4px
        ),
        textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ).copyWith(
        // Hover effect
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppTheme.primaryDark;
          }
          if (states.contains(WidgetState.disabled)) {
            return AppTheme.secondaryLight;
          }
          return AppTheme.primaryColor;
        }),
        // Splash effect
        overlayColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(text),
    );

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}