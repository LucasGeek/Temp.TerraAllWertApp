import 'package:flutter/foundation.dart';

/// Serviço para detectar plataforma
class PlatformService {
  /// Verifica se está rodando na web
  static bool get isWeb => kIsWeb;
  
  /// Verifica se está rodando no Android
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  
  /// Verifica se está rodando no iOS
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  
  /// Verifica se está rodando no desktop
  static bool get isDesktop => !kIsWeb && (
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.linux
  );
  
  /// Verifica se é mobile (Android ou iOS)
  static bool get isMobile => isAndroid || isIOS;
}