import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/presentation/providers/login_form_provider.dart';
import '../atoms/primary_button.dart';
import '../molecules/login_form_fields.dart';
import '../molecules/social_buttons_row.dart';

/// Organism: Formulário completo de login
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

      await ref.read(authControllerProvider.notifier).login(
            email: formState.email,
            password: formState.password,
          );

      ref.read(loginFormProvider.notifier).submitSuccess();
    } catch (error) {
      ref.read(loginFormProvider.notifier).submitError(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _focusNextField() {
    _passwordFocus.requestFocus();
  }

  void _handleSignUp() {
    // TODO: Implementar navegação para tela de cadastro
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }

  void _handleSocialLogin(String provider) {
    // TODO: Implementar login social
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login com $provider em desenvolvimento')),
    );
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
          // Título e subtítulo
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
          EmailField(
            focusNode: _emailFocus,
            errorText: formState.emailError,
            onChanged: (value) {
              ref.read(loginFormProvider.notifier).updateEmail(value);
            },
            onSubmitted: _focusNextField,
          ),
          const SizedBox(height: 20),

          // Campo de senha
          PasswordField(
            focusNode: _passwordFocus,
            errorText: formState.passwordError,
            onChanged: (value) {
              ref.read(loginFormProvider.notifier).updatePassword(value);
            },
            onSubmitted: _handleLogin,
          ),
          const SizedBox(height: 24),

          // Botão de login
          PrimaryButton(
            text: 'Entrar',
            isLoading: formState.isSubmitting,
            onPressed: formState.isValid && !formState.isSubmitting 
                ? _handleLogin 
                : null,
          ),
          
          // Mensagem de erro geral
          if (formState.submitError != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formState.submitError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Botões de login social
          SocialButtonsRow(
            onGooglePressed: () => _handleSocialLogin('Google'),
            onFacebookPressed: () => _handleSocialLogin('Facebook'),
            onApplePressed: () => _handleSocialLogin('Apple'),
          ),

          const SizedBox(height: 24),

          // Link para cadastro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Precisa de uma conta? ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              GestureDetector(
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
            ],
          ),
        ],
      ),
    );
  }
}