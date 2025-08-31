import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/terra_logo.dart';
import '../../../../core/widgets/templates/two_column_layout.dart';
import '../../../../core/widgets/organisms/login_form.dart';
import '../../../../core/theme/app_theme.dart';

/// Page: Tela de login com layout responsivo seguindo Material Design 2
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TwoColumnLayout(
      backgroundColor: AppTheme.backgroundColor,
      leftContent: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Terra Allwert (cabeçalho)
          const TerraLogo(
            size: 32,
            showText: true,
            alignment: MainAxisAlignment.start,
          ),
          
          const SizedBox(height: 48),
          
          // Formulário de login
          const Flexible(
            child: Center(
              child: SingleChildScrollView(
                child: LoginForm(),
              ),
            ),
          ),
        ],
      ),
      // Imagem à direita (será implementada depois)
      rightContent: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apartment,
                size: 120,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Visualize e gerencie\ntorres residenciais',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}