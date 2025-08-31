import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/components/atoms/terra_logo.dart';
import '../../../../widgets/components/templates/responsive_auth_layout.dart';
import '../../../../widgets/components/organisms/login_form.dart';
import '../../../../responsive/breakpoints.dart';

/// Page: Tela de login com layout responsivo seguindo Material Design 2
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usa tamanho de logo responsivo
    final logoSize = context.responsive<double>(
      xs: 28,
      sm: 30,
      md: 32,
      lg: 34,
      xl: 36,
      xxl: 40,
    );

    return ResponsiveAuthLayout(
      header: AppLogo(
        size: logoSize,
        showText: true,
        alignment: MainAxisAlignment.start,
      ),
      content: const LoginForm(),
    );
  }
}