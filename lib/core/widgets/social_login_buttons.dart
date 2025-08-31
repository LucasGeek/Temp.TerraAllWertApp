import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onFacebookPressed;
  final VoidCallback? onApplePressed;

  const SocialLoginButtons({
    super.key,
    this.onGooglePressed,
    this.onFacebookPressed,
    this.onApplePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider "ou entre com"
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou entre com',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Botões sociais
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SocialButton(
              icon: Icons.g_translate, // Placeholder para Google
              label: 'Google',
              onPressed: onGooglePressed,
            ),
            _SocialButton(
              icon: Icons.facebook, // Placeholder para Facebook
              label: 'Facebook', 
              onPressed: onFacebookPressed,
            ),
            _SocialButton(
              icon: Icons.apple, // Ícone Apple
              label: 'Apple',
              onPressed: onApplePressed,
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0, // Sem sombra
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          side: BorderSide(
            color: AppTheme.secondaryLight, 
            width: 1,
          ),
        ).copyWith(
          // Efeito ripple personalizado
          splashFactory: InkRipple.splashFactory,
          overlayColor: WidgetStateProperty.all(
            AppTheme.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          semanticLabel: 'Entrar com $label',
        ),
      ),
    );
  }
}

// Widget para link "Precisa de uma conta?"
class SignUpLink extends StatelessWidget {
  final VoidCallback? onPressed;

  const SignUpLink({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Precisa de uma conta? ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onPressed,
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
    );
  }
}