import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../layout/widgets/organisms/responsive_auth_layout.dart';
import '../../../providers/auth_provider.dart';
import '../providers/login_form_provider.dart';

/// Page: Tela de login com layout responsivo seguindo Material Design 2
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ResponsiveAuthLayout(
      content: LoginFormWidget(),
    );
  }
}

/// Widget de formulário de login
class LoginFormWidget extends ConsumerStatefulWidget {
  const LoginFormWidget({super.key});

  @override
  ConsumerState<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends ConsumerState<LoginFormWidget> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final formState = ref.watch(loginFormProvider);
    final isFormValid = ref.watch(isLoginFormValidProvider);

    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Entrar',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Acesse sua conta Terra Allwert',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Campo Email
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: const OutlineInputBorder(),
              errorText: formState.emailError,
            ),
            onChanged: (value) {
              ref.read(loginFormProvider.notifier).updateEmail(value);
            },
          ),
          const SizedBox(height: 16),

          // Campo Senha
          TextFormField(
            obscureText: formState.obscurePassword,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(formState.obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  ref.read(loginFormProvider.notifier).togglePasswordVisibility();
                },
              ),
              border: const OutlineInputBorder(),
              errorText: formState.passwordError,
            ),
            onChanged: (value) {
              ref.read(loginFormProvider.notifier).updatePassword(value);
            },
          ),
          const SizedBox(height: 24),

          // Botão Login
          ElevatedButton(
            onPressed: (isFormValid && !authState.isLoading) ? _handleLogin : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: authState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Entrar', style: TextStyle(fontSize: 16)),
          ),

        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final formState = ref.read(loginFormProvider);
    
    if (formState.isValid) {
      await ref.read(authProvider.notifier).login(
        formState.email.trim(),
        formState.password,
      );
    }
  }
}
