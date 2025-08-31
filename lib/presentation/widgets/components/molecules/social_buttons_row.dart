import 'package:flutter/material.dart';

import '../../../design_system/app_theme.dart';

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
            Expanded(child: Container(height: 1, color: AppTheme.secondaryLight)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou entre com',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
            Expanded(child: Container(height: 1, color: AppTheme.secondaryLight)),
          ],
        ),

        const SizedBox(height: 24),

        // Botões sociais
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SocialButton(
              icon: Icons.g_mobiledata,
              label: 'Google',
              color: Colors.red,
              onPressed: onGooglePressed,
            ),
            _SocialButton(
              icon: Icons.facebook,
              label: 'Facebook',
              color: Colors.blue,
              onPressed: onFacebookPressed,
            ),
            _SocialButton(
              icon: Icons.apple,
              label: 'Apple',
              color: Colors.black,
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
  final Color color;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
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
          elevation: 0,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: AppTheme.outline, width: 1),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(color.withValues(alpha: 0.1)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: color,
          semanticLabel: 'Entrar com $label',
        ),
      ),
    );
  }
}
