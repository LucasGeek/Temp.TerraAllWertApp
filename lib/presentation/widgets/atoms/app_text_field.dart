import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design_system/app_theme.dart';

/// Atom: Campo de texto reutilizável seguindo SOLID principles
/// Single Responsibility: Apenas renderizar campo de texto
/// Interface Segregation: Factory methods para diferentes tipos
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final String? initialValue;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.initialValue,
    this.autofocus = false,
  });

  /// Factory para campo de email
  factory AppTextField.email({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
    FocusNode? focusNode,
  }) => AppTextField(
    key: key,
    label: label ?? 'E-mail',
    hint: hint ?? 'Digite seu e-mail',
    errorText: errorText,
    prefixIcon: Icons.email_outlined,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    focusNode: focusNode,
  );

  /// Factory para campo de senha
  factory AppTextField.password({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmitted,
    FocusNode? focusNode,
    Widget? suffixIcon,
  }) => AppTextField(
    key: key,
    label: label ?? 'Senha',
    hint: hint ?? 'Digite sua senha',
    errorText: errorText,
    prefixIcon: Icons.lock_outline,
    suffixIcon: suffixIcon,
    obscureText: true,
    keyboardType: TextInputType.visiblePassword,
    textInputAction: TextInputAction.done,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    focusNode: focusNode,
  );

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _hasFocus = hasFocus;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) _buildLabel(context),
          _buildTextField(context),
          if (widget.errorText != null) _buildError(context),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField(BuildContext context) {
    return Container(
      decoration: _buildContainerDecoration(),
      child: TextFormField(
        controller: _controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        inputFormatters: widget.inputFormatters,
        autofocus: widget.autofocus,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.textPrimary,
        ),
        decoration: _buildInputDecoration(context),
        onChanged: widget.onChanged,
        onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Text(
          widget.errorText!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      boxShadow: _hasFocus && widget.errorText == null
          ? [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
    return InputDecoration(
      hintText: widget.hint,
      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppTheme.textHint,
      ),
      prefixIcon: widget.prefixIcon != null
          ? Icon(
              widget.prefixIcon,
              color: _getPrefixIconColor(),
              size: 20,
            )
          : null,
      suffixIcon: widget.suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: _buildBorder(AppTheme.secondaryLight, 1),
      enabledBorder: _buildBorder(_getEnabledBorderColor(), 1),
      focusedBorder: _buildBorder(_getFocusedBorderColor(), 2),
      errorBorder: _buildBorder(AppTheme.errorColor, 1),
      focusedErrorBorder: _buildBorder(AppTheme.errorColor, 2),
      filled: false,
      errorText: null, // Erro será mostrado separadamente
    );
  }

  Color _getPrefixIconColor() {
    if (widget.errorText != null) return AppTheme.errorColor;
    if (_hasFocus) return AppTheme.primaryColor;
    return AppTheme.textHint;
  }

  Color _getEnabledBorderColor() {
    return widget.errorText != null ? AppTheme.errorColor : AppTheme.secondaryLight;
  }

  Color _getFocusedBorderColor() {
    return widget.errorText != null ? AppTheme.errorColor : AppTheme.primaryColor;
  }

  OutlineInputBorder _buildBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppTextField.email() ou AppTextField.password()')
typedef LoginTextField = AppTextField;