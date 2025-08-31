import 'package:flutter/material.dart';
import '../../../design_system/app_theme.dart';
import '../../../responsive/breakpoints.dart';
import '../../../responsive/responsive_builder.dart';

/// Template responsivo para telas de autenticação (login, cadastro, etc)
class ResponsiveAuthLayout extends StatelessWidget {
  final Widget content;
  final Widget? header;
  final Widget? rightContent;
  final String? backgroundImagePath;

  const ResponsiveAuthLayout({
    super.key,
    required this.content,
    this.header,
    this.rightContent,
    this.backgroundImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ResponsiveBuilder(
        builder: (context, breakpoint) {
          switch (breakpoint) {
            case BreakpointSize.xs:
              return _buildMobileLayout(context);
            case BreakpointSize.sm:
              return _buildLargeMobileLayout(context);
            case BreakpointSize.md:
              return _buildTabletLayout(context);
            case BreakpointSize.lg:
              return _buildDesktopLayout(context);
            case BreakpointSize.xl:
              return _buildLargeDesktopLayout(context);
            case BreakpointSize.xxl:
              return _buildExtraLargeLayout(context);
          }
        },
      ),
    );
  }

  /// XS: < 640px - Mobile pequeno
  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header != null) ...[
                header!,
                const SizedBox(height: 32),
              ],
              content,
            ],
          ),
        ),
      ),
    );
  }

  /// SM: 640-768px - Mobile grande
  Widget _buildLargeMobileLayout(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header != null) ...[
                  header!,
                  const SizedBox(height: 40),
                ],
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// MD: 768-1024px - Tablet
  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Conteúdo principal (60%)
        Expanded(
          flex: 6,
          child: Container(
            color: AppTheme.surfaceColor,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (header != null) ...[
                        header!,
                        const SizedBox(height: 48),
                      ],
                      content,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Imagem lateral (40%)
        Expanded(
          flex: 4,
          child: _buildRightContent(context),
        ),
      ],
    );
  }

  /// LG: 1024-1280px - Desktop
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Conteúdo principal (45%)
        Expanded(
          flex: 45,
          child: Container(
            color: AppTheme.surfaceColor,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (header != null) ...[
                        header!,
                        const SizedBox(height: 56),
                      ],
                      content,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Imagem lateral (55%)
        Expanded(
          flex: 55,
          child: _buildRightContent(context),
        ),
      ],
    );
  }

  /// XL: 1280-1536px - Desktop grande
  Widget _buildLargeDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Conteúdo principal (40%)
        Expanded(
          flex: 4,
          child: Container(
            color: AppTheme.surfaceColor,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (header != null) ...[
                        header!,
                        const SizedBox(height: 64),
                      ],
                      content,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Imagem lateral (60%)
        Expanded(
          flex: 6,
          child: _buildRightContent(context),
        ),
      ],
    );
  }

  /// XXL: >= 1536px - Desktop muito grande
  Widget _buildExtraLargeLayout(BuildContext context) {
    return Row(
      children: [
        // Conteúdo principal (35%)
        Expanded(
          flex: 35,
          child: Container(
            color: AppTheme.surfaceColor,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 80,
                    vertical: 48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (header != null) ...[
                        header!,
                        const SizedBox(height: 72),
                      ],
                      content,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Imagem lateral (65%)
        Expanded(
          flex: 65,
          child: _buildRightContent(context),
        ),
      ],
    );
  }

  Widget _buildRightContent(BuildContext context) {
    if (rightContent != null) {
      return rightContent!;
    }

    if (backgroundImagePath != null) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImagePath!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Conteúdo padrão com gradiente
    return Container(
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
      child: Center(
        child: ResponsiveBuilder(
          builder: (context, breakpoint) {
            final iconSize = context.responsive<double>(
              xs: 80,
              sm: 100,
              md: 100,
              lg: 120,
              xl: 140,
              xxl: 160,
            );

            final fontSize = context.responsive<double>(
              xs: 18,
              sm: 20,
              md: 22,
              lg: 24,
              xl: 26,
              xxl: 28,
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.apartment,
                  size: iconSize,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 24),
                Text(
                  'Visualize e gerencie\ntorres residenciais',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}