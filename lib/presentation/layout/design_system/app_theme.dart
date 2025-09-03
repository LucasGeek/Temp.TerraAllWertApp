import 'package:flutter/material.dart';

class AppTheme {
  // Terra Allwert Color Palette - Nova identidade visual

  // 🔹 Cores Primárias
  static const Color primaryColor = Color(0xFF12281E); // Verde escuro institucional
  static const Color onPrimary = Color(0xFFFFFFFF); // Branco

  // 🔹 Cores Secundárias
  static const Color secondaryColor = Color(0xFFA3D15E); // Verde-lima
  static const Color onSecondary = Color(0xFF212121); // Preto quase puro

  // 🔹 Cores Neutras (Background / Surface / Outline)
  static const Color backgroundColor = Color(0xFFF1F3F2); // Cinza claro específico
  static const Color surfaceColor = Color(0xFFFFFFFF); // Branco puro
  static const Color surfaceVariant = Color(0xFFE0E0E0); // Cinza médio
  static const Color onSurface = Color(0xFF212121); // Preto suave
  static const Color onSurfaceVariant = Color(0xFF616161); // Cinza escuro
  static const Color outline = Color(0xFFBDBDBD); // Cinza

  // 🔹 Estados e Feedback
  static const Color errorColor = Color(0xFFD32F2F); // Vermelho
  static const Color onError = Color(0xFFFFFFFF); // Branco
  static const Color successColor = Color(0xFF4CAF50); // Verde
  static const Color warningColor = Color(0xFFFBC02D); // Amarelo
  static const Color infoColor = Color(0xFF2196F3); // Azul médio

  // Legacy colors para transição gradual
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textHint = Color(0xFF9E9E9E);

  // Cores especiais para componentes
  static const Color disabledColor = Color(0xFFBDBDBD);

  // Cores de compatibilidade (serão removidas gradualmente)
  static const Color primaryLight = Color(0xFF1A3328); // Verde escuro mais claro
  static const Color primaryDark = Color(0xFF0F1F18); // Verde escuro mais escuro
  static const Color secondaryLight = outline; // Usando outline como substituto

  // Estados de interação (hover/pressed/disabled)
  static const Color primaryHover = Color(0xFF1A3328); // Verde escuro mais claro para hover
  static const Color primaryPressed = Color(0xFF0F1F18); // Verde escuro mais escuro para pressed
  static const Color secondaryHover = Color(0xFF8FC44F); // Verde-lima mais escuro para hover
  static const Color secondaryPressed = Color(
    0xFF7FB142,
  ); // Verde-lima ainda mais escuro para pressed
  static const Color disabledBackground = Color(0xFFE0E0E0); // Cinza claro para disabled
  static const Color disabledText = Color(0xFF9E9E9E); // Cinza médio para texto disabled

  static ThemeData lightTheme = ThemeData(
    useMaterial3: false, // Material Design 2
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
    ),
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,

    // AppBar com fundo branco
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor, // Branco puro
      foregroundColor: onSurface, // Preto
      elevation: 0,
      centerTitle: false, // Alinhado à esquerda
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: onSurface, // Preto
      ),
    ),

    // Botões principais - Verde-lima com texto preto
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return disabledBackground;
          }
          if (states.contains(WidgetState.pressed)) {
            return secondaryPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return secondaryHover;
          }
          return secondaryColor; // Verde-lima para botões principais
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return disabledText;
          }
          return onSecondary; // Preto sobre verde-lima
        }),
        elevation: WidgetStateProperty.all(2),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    ),

    // Botões secundários - Borda verde-escuro, fundo branco, texto verde-escuro
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return disabledBackground;
          }
          if (states.contains(WidgetState.pressed)) {
            return primaryColor.withValues(alpha: 0.1); // Verde escuro
          }
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withValues(alpha: 0.05); // Verde escuro
          }
          return surfaceColor; // Branco
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return disabledText;
          }
          return primaryColor; // Verde escuro
        }),
        elevation: WidgetStateProperty.all(0),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        side: WidgetStateProperty.resolveWith<BorderSide>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: disabledText, width: 1);
          }
          return BorderSide(color: primaryColor, width: 1); // Borda verde escuro
        }),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    ),

    // Campos de texto com borda primária
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: outline, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: outline, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: secondaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      hintStyle: TextStyle(color: onSurfaceVariant),
      labelStyle: TextStyle(color: onSurfaceVariant),
    ),

    // Tipografia com hierarquia clara
    textTheme: const TextTheme(
      // Títulos principais (H1) - Preto
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: onSurface, // Preto
        height: 1.2,
      ),
      // Títulos secundários (H2) - Preto
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: onSurface, // Preto
        height: 1.3,
      ),
      // Títulos terciários (H3) - Preto
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onSurface, // Preto
        height: 1.3,
      ),
      // Títulos de seção - Preto
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: onSurface, // Preto
        height: 1.4,
      ),
      // Texto principal - Preto
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: onSurface, // Preto
        height: 1.5,
      ),
      // Subtitulos/labels - Cinza escuro
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: onSurfaceVariant, // Cinza escuro
        height: 1.4,
      ),
      // Legendas pequenas - Cinza escuro
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: onSurfaceVariant, // Cinza escuro
        height: 1.3,
      ),
      // Labels de campos - Cinza escuro
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant, // Cinza escuro
        height: 1.4,
      ),
    ),

    // Cards com fundo branco sobre cinza claro
    cardTheme: CardThemeData(
      elevation: 1,
      color: surfaceColor, // Branco puro
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Links e ações clicáveis - Verde-lima
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return disabledText;
          }
          if (states.contains(WidgetState.pressed)) {
            return secondaryPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return secondaryHover;
          }
          return secondaryColor; // Verde-lima para links
        }),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark),
    appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0, scrolledUnderElevation: 1),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
