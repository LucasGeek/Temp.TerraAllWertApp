import 'package:flutter/material.dart';

/// Sistema de breakpoints responsivos seguindo padrões mundiais
/// Baseado em Tailwind CSS e Bootstrap
class Breakpoints {
  // Breakpoint values em pixels
  static const double xs = 0;     // Extra small (mobile)
  static const double sm = 640;   // Small (large mobile)
  static const double md = 768;   // Medium (tablet)
  static const double lg = 1024;  // Large (desktop)
  static const double xl = 1280;  // Extra large (large desktop)
  static const double xxl = 1536; // 2XL (very large desktop)

  // Helper methods para verificar breakpoints
  static bool isXs(BuildContext context) => 
      MediaQuery.of(context).size.width < sm;
  
  static bool isSm(BuildContext context) => 
      MediaQuery.of(context).size.width >= sm && 
      MediaQuery.of(context).size.width < md;
  
  static bool isMd(BuildContext context) => 
      MediaQuery.of(context).size.width >= md && 
      MediaQuery.of(context).size.width < lg;
  
  static bool isLg(BuildContext context) => 
      MediaQuery.of(context).size.width >= lg && 
      MediaQuery.of(context).size.width < xl;
  
  static bool isXl(BuildContext context) => 
      MediaQuery.of(context).size.width >= xl && 
      MediaQuery.of(context).size.width < xxl;
  
  static bool isXxl(BuildContext context) => 
      MediaQuery.of(context).size.width >= xxl;

  // Helpers para grupos de breakpoints
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < md;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= md && 
      MediaQuery.of(context).size.width < lg;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= lg;

  // Helper para obter o breakpoint atual
  static BreakpointSize current(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= xxl) return BreakpointSize.xxl;
    if (width >= xl) return BreakpointSize.xl;
    if (width >= lg) return BreakpointSize.lg;
    if (width >= md) return BreakpointSize.md;
    if (width >= sm) return BreakpointSize.sm;
    return BreakpointSize.xs;
  }

  // Helper para obter valor baseado no breakpoint
  static T value<T>({
    required BuildContext context,
    required T xs,
    T? sm,
    T? md,
    T? lg,
    T? xl,
    T? xxl,
  }) {
    final breakpoint = current(context);
    
    switch (breakpoint) {
      case BreakpointSize.xxl:
        return xxl ?? xl ?? lg ?? md ?? sm ?? xs;
      case BreakpointSize.xl:
        return xl ?? lg ?? md ?? sm ?? xs;
      case BreakpointSize.lg:
        return lg ?? md ?? sm ?? xs;
      case BreakpointSize.md:
        return md ?? sm ?? xs;
      case BreakpointSize.sm:
        return sm ?? xs;
      case BreakpointSize.xs:
        return xs;
    }
  }
}

/// Enum para representar os tamanhos de breakpoint
enum BreakpointSize {
  xs, // < 640px
  sm, // >= 640px
  md, // >= 768px
  lg, // >= 1024px
  xl, // >= 1280px
  xxl, // >= 1536px
}

/// Extension para facilitar o uso dos breakpoints
extension BreakpointExtension on BuildContext {
  BreakpointSize get breakpoint => Breakpoints.current(this);
  
  bool get isXs => Breakpoints.isXs(this);
  bool get isSm => Breakpoints.isSm(this);
  bool get isMd => Breakpoints.isMd(this);
  bool get isLg => Breakpoints.isLg(this);
  bool get isXl => Breakpoints.isXl(this);
  bool get isXxl => Breakpoints.isXxl(this);
  
  bool get isMobile => Breakpoints.isMobile(this);
  bool get isTablet => Breakpoints.isTablet(this);
  bool get isDesktop => Breakpoints.isDesktop(this);
  
  T responsive<T>({
    required T xs,
    T? sm,
    T? md,
    T? lg,
    T? xl,
    T? xxl,
  }) => Breakpoints.value(
    context: this,
    xs: xs,
    sm: sm,
    md: md,
    lg: lg,
    xl: xl,
    xxl: xxl,
  );
}