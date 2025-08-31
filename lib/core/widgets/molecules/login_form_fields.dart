import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../atoms/login_text_field.dart';

/// Molecule: Campo de email específico para login
class EmailField extends StatelessWidget {
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const EmailField({
    super.key,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return LoginTextField(
      label: 'Email',
      hint: 'example@email.com',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // Remove espaços
      ],
      initialValue: initialValue,
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}

/// Molecule: Campo de senha específico para login
class PasswordField extends StatefulWidget {
  final String? initialValue;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const PasswordField({
    super.key,
    this.initialValue,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoginTextField(
      label: 'Senha',
      hint: 'Digite sua senha',
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword 
              ? Icons.visibility_outlined 
              : Icons.visibility_off_outlined,
          color: AppTheme.textHint,
          size: 20,
        ),
        onPressed: _togglePasswordVisibility,
        splashRadius: 20,
        tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
      ),
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      initialValue: widget.initialValue,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
    );
  }
}