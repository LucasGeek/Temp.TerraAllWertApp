import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/login_form_provider.dart';
import '../../../../core/widgets/validated_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _login() async {
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

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loginFormProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Terra Allwert',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              
              // Email Field
              EmailTextField(
                focusNode: _emailFocus,
                errorText: formState.emailError,
                onChanged: (value) {
                  ref.read(loginFormProvider.notifier).updateEmail(value);
                },
                onSubmitted: _focusNextField,
              ),
              
              const SizedBox(height: 16),
              
              // Password Field
              PasswordTextField(
                focusNode: _passwordFocus,
                obscureText: formState.obscurePassword,
                errorText: formState.passwordError,
                onChanged: (value) {
                  ref.read(loginFormProvider.notifier).updatePassword(value);
                },
                onToggleVisibility: () {
                  ref.read(loginFormProvider.notifier).togglePasswordVisibility();
                },
                onSubmitted: _login,
              ),
              
              const SizedBox(height: 24),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: formState.isSubmitting ? null : _login,
                  child: formState.isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Entrar'),
                ),
              ),
              
              // Error Message
              if (formState.submitError != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Erro: ${formState.submitError}',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}