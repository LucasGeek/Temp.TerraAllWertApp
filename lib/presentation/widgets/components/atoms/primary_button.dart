import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';

/// Atom: Botão reutilizável seguindo SOLID principles
/// Single Responsibility: Apenas renderizar botão com estado de loading
/// Open/Closed: Extensível via factory methods e variantes
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets padding;
  final ButtonVariant variant;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.variant = ButtonVariant.primary,
    this.icon,
  });

  /// Factory para botão primário
  factory AppButton.primary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    isLoading: isLoading,
    isFullWidth: isFullWidth,
    variant: ButtonVariant.primary,
    icon: icon,
  );

  /// Factory para botão secundário
  factory AppButton.secondary({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = true,
    IconData? icon,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    isLoading: isLoading,
    isFullWidth: isFullWidth,
    variant: ButtonVariant.secondary,
    icon: icon,
  );

  /// Factory para botão de texto
  factory AppButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    IconData? icon,
  }) => AppButton(
    key: key,
    text: text,
    onPressed: onPressed,
    isLoading: isLoading,
    isFullWidth: false,
    variant: ButtonVariant.text,
    icon: icon,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
        return _buildElevatedButton(context);
      case ButtonVariant.secondary:
        return _buildOutlinedButton(context);
      case ButtonVariant.text:
        return _buildTextButton(context);
    }
  }

  Widget _buildElevatedButton(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.secondaryLight,
        disabledForegroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
        padding: padding,
        minimumSize: Size(isFullWidth ? double.infinity : 120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(_getBackgroundColor),
        overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        disabledForegroundColor: AppTheme.secondaryLight,
        padding: padding,
        minimumSize: Size(isFullWidth ? double.infinity : 120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(color: AppTheme.primaryColor, width: 1),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        disabledForegroundColor: AppTheme.secondaryLight,
        padding: padding,
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == ButtonVariant.primary ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  Color _getBackgroundColor(Set<WidgetState> states) {
    if (states.contains(WidgetState.hovered)) {
      return AppTheme.primaryDark;
    }
    if (states.contains(WidgetState.disabled)) {
      return AppTheme.secondaryLight;
    }
    return AppTheme.primaryColor;
  }
}

/// Enum para variantes do botão seguindo Open/Closed Principle
enum ButtonVariant {
  primary,
  secondary,
  text,
}

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppButton.primary() ao invés de PrimaryButton')
typedef PrimaryButton = AppButton;