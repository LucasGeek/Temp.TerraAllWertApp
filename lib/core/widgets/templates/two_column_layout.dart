import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Template: Layout responsivo de duas colunas para login
class TwoColumnLayout extends StatelessWidget {
  final Widget leftContent;
  final Widget? rightContent;
  final String? backgroundImagePath;
  final Color backgroundColor;

  const TwoColumnLayout({
    super.key,
    required this.leftContent,
    this.rightContent,
    this.backgroundImagePath,
    this.backgroundColor = AppTheme.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        final isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return _MobileLayout(
            backgroundColor: backgroundColor,
            child: leftContent,
          );
        } else if (isTablet) {
          return _TabletLayout(
            leftContent: leftContent,
            rightContent: rightContent,
            backgroundImagePath: backgroundImagePath,
            backgroundColor: backgroundColor,
          );
        } else {
          return _DesktopLayout(
            leftContent: leftContent,
            rightContent: rightContent,
            backgroundImagePath: backgroundImagePath,
            backgroundColor: backgroundColor,
          );
        }
      },
    );
  }
}

/// Layout para desktop (>=1024px)
class _DesktopLayout extends StatelessWidget {
  final Widget leftContent;
  final Widget? rightContent;
  final String? backgroundImagePath;
  final Color backgroundColor;

  const _DesktopLayout({
    required this.leftContent,
    this.rightContent,
    this.backgroundImagePath,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Coluna esquerda (40%)
          Expanded(
            flex: 4,
            child: Container(
              color: AppTheme.surfaceColor,
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: leftContent,
                ),
              ),
            ),
          ),
          
          // Coluna direita (60%) - Imagem
          if (rightContent != null)
            Expanded(
              flex: 6,
              child: rightContent!,
            )
          else if (backgroundImagePath != null)
            Expanded(
              flex: 6,
              child: _BackgroundImage(imagePath: backgroundImagePath!),
            )
          else
            Expanded(
              flex: 6,
              child: Container(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                child: const Center(
                  child: Icon(
                    Icons.apartment,
                    size: 120,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Layout para tablet (768px-1024px)
class _TabletLayout extends StatelessWidget {
  final Widget leftContent;
  final Widget? rightContent;
  final String? backgroundImagePath;
  final Color backgroundColor;

  const _TabletLayout({
    required this.leftContent,
    this.rightContent,
    this.backgroundImagePath,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Coluna esquerda (50%)
          Expanded(
            flex: 1,
            child: Container(
              color: AppTheme.surfaceColor,
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: leftContent,
                ),
              ),
            ),
          ),
          
          // Coluna direita (50%)
          if (rightContent != null)
            Expanded(
              flex: 1,
              child: rightContent!,
            )
          else if (backgroundImagePath != null)
            Expanded(
              flex: 1,
              child: _BackgroundImage(imagePath: backgroundImagePath!),
            )
          else
            Expanded(
              flex: 1,
              child: Container(
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
                child: const Center(
                  child: Icon(
                    Icons.apartment,
                    size: 80,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Layout para mobile (<768px)
class _MobileLayout extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const _MobileLayout({
    required this.child,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16), // Padding interno ~16dp
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 32,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Widget para imagem de fundo
class _BackgroundImage extends StatelessWidget {
  final String imagePath;

  const _BackgroundImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}