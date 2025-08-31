import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/layout_constants.dart';
import '../atoms/responsive_text.dart';

/// Molecule: Botões de login social seguindo SOLID principles
/// Single Responsibility: Apenas renderizar botões de autenticação social
/// Open/Closed: Extensível via factory methods e configurações
class AppSocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final VoidCallback? onFacebookPressed;
  final VoidCallback? onApplePressed;
  final String? dividerText;
  final SocialButtonVariant variant;
  final MainAxisAlignment alignment;
  final double spacing;
  final bool showDivider;
  
  const AppSocialLoginButtons({
    super.key,
    this.onGooglePressed,
    this.onFacebookPressed,
    this.onApplePressed,
    this.dividerText,
    this.variant = SocialButtonVariant.standard,
    this.alignment = MainAxisAlignment.spaceEvenly,
    this.spacing = 24,
    this.showDivider = true,
  });

  /// Factory para botões com ícones SVG
  factory AppSocialLoginButtons.withSvg({
    Key? key,
    VoidCallback? onGooglePressed,
    VoidCallback? onFacebookPressed,
    VoidCallback? onApplePressed,
    String? dividerText,
    MainAxisAlignment alignment = MainAxisAlignment.spaceEvenly,
    bool showDivider = true,
  }) => AppSocialLoginButtons(
    key: key,
    onGooglePressed: onGooglePressed,
    onFacebookPressed: onFacebookPressed,
    onApplePressed: onApplePressed,
    dividerText: dividerText,
    variant: SocialButtonVariant.svg,
    alignment: alignment,
    showDivider: showDivider,
  );

  /// Factory para botões com ícones Material
  factory AppSocialLoginButtons.withIcons({
    Key? key,
    VoidCallback? onGooglePressed,
    VoidCallback? onFacebookPressed,
    VoidCallback? onApplePressed,
    String? dividerText,
    MainAxisAlignment alignment = MainAxisAlignment.spaceEvenly,
    bool showDivider = true,
  }) => AppSocialLoginButtons(
    key: key,
    onGooglePressed: onGooglePressed,
    onFacebookPressed: onFacebookPressed,
    onApplePressed: onApplePressed,
    dividerText: dividerText,
    variant: SocialButtonVariant.materialIcons,
    alignment: alignment,
    showDivider: showDivider,
  );

  /// Factory compacto sem divider
  factory AppSocialLoginButtons.compact({
    Key? key,
    VoidCallback? onGooglePressed,
    VoidCallback? onFacebookPressed,
    VoidCallback? onApplePressed,
  }) => AppSocialLoginButtons(
    key: key,
    onGooglePressed: onGooglePressed,
    onFacebookPressed: onFacebookPressed,
    onApplePressed: onApplePressed,
    variant: SocialButtonVariant.compact,
    alignment: MainAxisAlignment.center,
    spacing: 12,
    showDivider: false,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider) ...[
          _buildDivider(context),
          SizedBox(height: spacing),
        ],
        _buildButtons(),
      ],
    );
  }
  
  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppText.body(
            dividerText ?? 'ou entre com',
            color: AppTheme.textSecondary,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
  
  Widget _buildButtons() {
    final buttons = <Widget>[];
    
    if (onGooglePressed != null) {
      buttons.add(_buildSocialButton(
        provider: SocialProvider.google,
        onPressed: onGooglePressed!,
      ));
    }
    
    if (onFacebookPressed != null) {
      buttons.add(_buildSocialButton(
        provider: SocialProvider.facebook,
        onPressed: onFacebookPressed!,
      ));
    }
    
    if (onApplePressed != null) {
      buttons.add(_buildSocialButton(
        provider: SocialProvider.apple,
        onPressed: onApplePressed!,
      ));
    }
    
    if (variant == SocialButtonVariant.compact) {
      return Wrap(
        spacing: 12,
        children: buttons,
      );
    }
    
    return Row(
      mainAxisAlignment: alignment,
      children: buttons,
    );
  }
  
  Widget _buildSocialButton({
    required SocialProvider provider,
    required VoidCallback onPressed,
  }) {
    return _AppSocialButton(
      provider: provider,
      variant: variant,
      onPressed: onPressed,
    );
  }
}

/// Botão social individual
class _AppSocialButton extends StatelessWidget {
  final SocialProvider provider;
  final SocialButtonVariant variant;
  final VoidCallback onPressed;

  const _AppSocialButton({
    required this.provider,
    required this.variant,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getSocialConfig(provider);
    final size = variant == SocialButtonVariant.compact ? 40.0 : 48.0;
    final iconSize = variant == SocialButtonVariant.compact ? 16.0 : 20.0;
    
    return SizedBox(
      width: variant == SocialButtonVariant.compact ? size : 64,
      height: size,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surfaceColor,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              variant == SocialButtonVariant.compact 
                  ? LayoutConstants.radiusSmall 
                  : LayoutConstants.radiusSmall,
            ),
          ),
          side: BorderSide(
            color: AppTheme.outline,
            width: 1,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(
            config.color.withValues(alpha: 0.1),
          ),
        ),
        child: _buildButtonContent(config, iconSize),
      ),
    );
  }
  
  Widget _buildButtonContent(_SocialConfig config, double iconSize) {
    switch (variant) {
      case SocialButtonVariant.svg:
        return SvgPicture.asset(
          config.svgPath,
          width: iconSize,
          height: iconSize,
          semanticsLabel: 'Entrar com ${config.label}',
        );
      case SocialButtonVariant.materialIcons:
      case SocialButtonVariant.standard:
      case SocialButtonVariant.compact:
        return Icon(
          config.icon,
          size: iconSize,
          color: config.color,
          semanticLabel: 'Entrar com ${config.label}',
        );
    }
  }
  
  _SocialConfig _getSocialConfig(SocialProvider provider) {
    switch (provider) {
      case SocialProvider.google:
        return _SocialConfig(
          label: 'Google',
          icon: Icons.g_mobiledata,
          color: Colors.red,
          svgPath: 'assets/images/icons/google-icon.svg',
        );
      case SocialProvider.facebook:
        return _SocialConfig(
          label: 'Facebook',
          icon: Icons.facebook,
          color: Colors.blue,
          svgPath: 'assets/images/icons/facebook-icon.svg',
        );
      case SocialProvider.apple:
        return _SocialConfig(
          label: 'Apple',
          icon: Icons.apple,
          color: Colors.black,
          svgPath: 'assets/images/icons/apple-icon.svg',
        );
    }
  }
}

/// Widget para link de cadastro
class AppSignUpLink extends StatelessWidget {
  final String? text;
  final String? linkText;
  final VoidCallback? onPressed;
  final MainAxisAlignment alignment;

  const AppSignUpLink({
    super.key,
    this.text,
    this.linkText,
    this.onPressed,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        AppText.caption(
          text ?? 'Precisa de uma conta? ',
          color: AppTheme.textSecondary,
        ),
        GestureDetector(
          onTap: onPressed,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AppText.caption(
              linkText ?? 'Crie aqui',
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Configuração para cada provedor social
class _SocialConfig {
  final String label;
  final IconData icon;
  final Color color;
  final String svgPath;
  
  const _SocialConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.svgPath,
  });
}

/// Enum para provedores sociais
enum SocialProvider {
  google,
  facebook,
  apple,
}

/// Enum para variantes dos botões - Open/Closed Principle
enum SocialButtonVariant {
  standard,
  svg,
  materialIcons,
  compact,
}

/// Backward compatibility - será removido em versão futura
@Deprecated('Use AppSocialLoginButtons ao invés de SocialLoginButtons')
typedef SocialLoginButtons = AppSocialLoginButtons;

@Deprecated('Use AppSignUpLink ao invés de SignUpLink')
typedef SignUpLink = AppSignUpLink;