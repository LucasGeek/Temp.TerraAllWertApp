import 'package:flutter/material.dart';
import 'breakpoints.dart';

/// Widget builder responsivo que adapta o layout baseado em breakpoints
class ResponsiveBuilder extends StatelessWidget {
  final Widget? xs;
  final Widget? sm;
  final Widget? md;
  final Widget? lg;
  final Widget? xl;
  final Widget? xxl;
  
  /// Builder function que recebe o contexto e o breakpoint atual
  final Widget Function(BuildContext context, BreakpointSize breakpoint)? builder;

  const ResponsiveBuilder({
    super.key,
    this.xs,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
    this.builder,
  }) : assert(
    xs != null || builder != null,
    'Você deve fornecer pelo menos xs ou builder',
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = _getBreakpoint(constraints.maxWidth);
        
        // Se tiver builder, usa ele
        if (builder != null) {
          return builder!(context, breakpoint);
        }
        
        // Caso contrário, retorna o widget apropriado
        switch (breakpoint) {
          case BreakpointSize.xxl:
            return xxl ?? xl ?? lg ?? md ?? sm ?? xs!;
          case BreakpointSize.xl:
            return xl ?? lg ?? md ?? sm ?? xs!;
          case BreakpointSize.lg:
            return lg ?? md ?? sm ?? xs!;
          case BreakpointSize.md:
            return md ?? sm ?? xs!;
          case BreakpointSize.sm:
            return sm ?? xs!;
          case BreakpointSize.xs:
            return xs!;
        }
      },
    );
  }

  BreakpointSize _getBreakpoint(double width) {
    if (width >= Breakpoints.xxl) return BreakpointSize.xxl;
    if (width >= Breakpoints.xl) return BreakpointSize.xl;
    if (width >= Breakpoints.lg) return BreakpointSize.lg;
    if (width >= Breakpoints.md) return BreakpointSize.md;
    if (width >= Breakpoints.sm) return BreakpointSize.sm;
    return BreakpointSize.xs;
  }
}

/// Widget para aplicar padding responsivo
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets xs;
  final EdgeInsets? sm;
  final EdgeInsets? md;
  final EdgeInsets? lg;
  final EdgeInsets? xl;
  final EdgeInsets? xxl;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.xs = const EdgeInsets.all(16),
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.responsive(
        xs: xs,
        sm: sm,
        md: md,
        lg: lg,
        xl: xl,
        xxl: xxl,
      ),
      child: child,
    );
  }
}

/// Widget para container com largura máxima responsiva
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final defaultMaxWidth = context.responsive<double>(
      xs: double.infinity,
      sm: 540,
      md: 720,
      lg: 960,
      xl: 1140,
      xxl: 1320,
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? defaultMaxWidth,
        ),
        child: child,
      ),
    );
  }
}

/// Grid responsivo que ajusta colunas baseado no breakpoint
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int xs;
  final int? sm;
  final int? md;
  final int? lg;
  final int? xl;
  final int? xxl;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.xs = 1,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(
      xs: xs,
      sm: sm,
      md: md,
      lg: lg,
      xl: xl,
      xxl: xxl,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) => SizedBox(
            width: itemWidth,
            child: child,
          )).toList(),
        );
      },
    );
  }
}