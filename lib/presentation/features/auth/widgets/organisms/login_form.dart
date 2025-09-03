import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../layout/design_system/app_theme.dart';
import '../../../../layout/widgets/atoms/primary_button.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/notification/snackbar_notification.dart';
import '../../providers/login_form_provider.dart';
import '../molecules/form_fields.dart';
import '../molecules/social_login_buttons.dart';

/// Organism: Formulário completo de login baseado no design do app-layout
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final formState = ref.read(loginFormProvider);

    if (!formState.isValid) {
      ref.read(loginFormProvider.notifier).validate();
      return;
    }

    try {
      ref.read(loginFormProvider.notifier).startSubmitting();

      await ref.read(authProvider.notifier).login(
        formState.email,
        formState.password,
      );

      ref.read(loginFormProvider.notifier).submitSuccess();
      
      // Show success message
      SnackbarNotification.showSuccess('Login realizado com sucesso!');
      
      // Navigate to dashboard after successful login
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (error) {
      final errorMessage = error.toString();
      ref.read(loginFormProvider.notifier).submitError(errorMessage);
      SnackbarNotification.showError(errorMessage);
    }
  }

  void _focusNextField() {
    _passwordFocus.requestFocus();
  }

  void _handleSignUp() {
    SnackbarNotification.showInfo('Funcionalidade de cadastro em desenvolvimento');
  }

  void _handleSocialLogin(String provider) {
    SnackbarNotification.showInfo('Login com $provider em desenvolvimento');
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loginFormProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Títulos estilizados
          Text(
            'Comece sua jornada',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entre no Terra Allwert',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          // Campo de email
          AppFormField.email(
            focusNode: _emailFocus,
            errorText: formState.emailError,
            onChanged: (value) {
              ref.read(loginFormProvider.notifier).updateEmail(value);
            },
            onSubmitted: _focusNextField,
          ),
          const SizedBox(height: 20),

          // Campo de senha
          AppFormField.password(
            focusNode: _passwordFocus,
            errorText: formState.passwordError,
            onChanged: (value) {
              ref.read(loginFormProvider.notifier).updatePassword(value);
            },
            onSubmitted: _handleLogin,
          ),
          const SizedBox(height: 24),

          // Botão de login
          AppButton.primary(
            text: 'Entrar',
            isLoading: formState.isSubmitting,
            onPressed: formState.isValid && !formState.isSubmitting 
                ? _handleLogin 
                : null,
          ),

          const SizedBox(height: 32),

          // Botões de login social
          AppSocialLoginButtons(
            onGooglePressed: () => _handleSocialLogin('Google'),
            onFacebookPressed: () => _handleSocialLogin('Facebook'),
            onApplePressed: () => _handleSocialLogin('Apple'),
          ),

          const SizedBox(height: 24),

          // Link para cadastro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Precisa de uma conta? ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: GestureDetector(
                  onTap: _handleSignUp,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      'Crie aqui',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}