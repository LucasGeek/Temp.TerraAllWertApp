import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Molecule: Linha de botões de login social
class SocialButtonsRow extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onFacebookPressed;
  final VoidCallback? onApplePressed;

  const SocialButtonsRow({
    super.key,
    this.onGooglePressed,
    this.onFacebookPressed,
    this.onApplePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider com texto
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.secondaryLight,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou entre com',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.secondaryLight,
              ),
            ),
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

/// Atom: Botão de login social individual
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
      height: 48, // Área mínima de toque
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0, // Sem sombra conforme especificação
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