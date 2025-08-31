import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

enum AppPlatform { web, android, ios, macos, windows, linux }

class PlatformService {
  static AppPlatform get current {
    if (kIsWeb) return AppPlatform.web;
    
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isIOS) return AppPlatform.ios;
    if (Platform.isMacOS) return AppPlatform.macos;
    if (Platform.isWindows) return AppPlatform.windows;
    if (Platform.isLinux) return AppPlatform.linux;
    
    return AppPlatform.web;
  }

  static bool get isMobile => current == AppPlatform.android || current == AppPlatform.ios;
  static bool get isDesktop => current == AppPlatform.macos || current == AppPlatform.windows || current == AppPlatform.linux;
  static bool get isWeb => current == AppPlatform.web;

  static bool get supportsIsolates => !kIsWeb;
  static bool get supportsFileSystem => !kIsWeb;
  static bool get supportsBackgroundTasks => isMobile;
  static bool get supportsBiometrics => isMobile;
  static bool get supportsNativeDownloads => !kIsWeb;
  static bool get supportsLocalNotifications => !kIsWeb;

  static String get platformName {
    switch (current) {
      case AppPlatform.web:
        return 'Web';
      case AppPlatform.android:
        return 'Android';
      case AppPlatform.ios:
        return 'iOS';
      case AppPlatform.macos:
        return 'macOS';
      case AppPlatform.windows:
        return 'Windows';
      case AppPlatform.linux:
        return 'Linux';
    }
  }

  static Map<String, String> get platformCapabilities {
    return {
      'name': platformName,
      'isolates': supportsIsolates.toString(),
      'fileSystem': supportsFileSystem.toString(),
      'backgroundTasks': supportsBackgroundTasks.toString(),
      'biometrics': supportsBiometrics.toString(),
      'nativeDownloads': supportsNativeDownloads.toString(),
      'localNotifications': supportsLocalNotifications.toString(),
    };
  }
}