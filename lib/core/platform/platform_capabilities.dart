import 'package:flutter/foundation.dart';
import 'platform_service.dart';

class PlatformCapabilities {
  // Cache capabilities
  static bool get supportsFileCache => PlatformService.supportsFileSystem;
  static bool get supportsMemoryCache => true;
  static bool get supportsSecureStorage => !PlatformService.isWeb;
  
  // Download capabilities
  static bool get supportsNativeDownloads => !PlatformService.isWeb;
  static bool get supportsBrowserDownloads => PlatformService.isWeb;
  static bool get supportsBackgroundDownloads => PlatformService.isMobile;
  static bool get supportsDownloadNotifications => PlatformService.isMobile;
  
  // Concurrency capabilities
  static bool get supportsIsolates => !PlatformService.isWeb;
  static bool get supportsWebWorkers => PlatformService.isWeb;
  static bool get supportsMultiThreading => !PlatformService.isWeb;
  static int get recommendedThreadCount => PlatformService.isMobile ? 2 : 4;
  
  // Storage capabilities
  static bool get supportsLocalDatabase => true;
  static bool get supportsFileSystem => PlatformService.supportsFileSystem;
  static bool get supportsDirectoryAccess => !PlatformService.isWeb;
  
  // Network capabilities
  static bool get supportsOfflineMode => true;
  static bool get supportsBackgroundSync => PlatformService.isMobile;
  static bool get supportsConnectivityCheck => true;
  
  // UI capabilities
  static bool get supportsBiometrics => PlatformService.supportsBiometrics;
  static bool get supportsNativeNavigation => !PlatformService.isWeb;
  static bool get supportsFullscreen => true;
  static bool get supportsSystemNotifications => PlatformService.supportsLocalNotifications;
  
  // Performance recommendations
  static Map<String, int> get performanceLimits {
    if (PlatformService.isWeb) {
      return {
        'maxConcurrentDownloads': 3,
        'maxCacheSize': 50 * 1024 * 1024, // 50MB
        'maxImageCacheSize': 20 * 1024 * 1024, // 20MB
        'maxDatabaseSize': 100 * 1024 * 1024, // 100MB
      };
    } else if (PlatformService.isMobile) {
      return {
        'maxConcurrentDownloads': 5,
        'maxCacheSize': 200 * 1024 * 1024, // 200MB
        'maxImageCacheSize': 100 * 1024 * 1024, // 100MB
        'maxDatabaseSize': 500 * 1024 * 1024, // 500MB
      };
    } else {
      return {
        'maxConcurrentDownloads': 10,
        'maxCacheSize': 1024 * 1024 * 1024, // 1GB
        'maxImageCacheSize': 500 * 1024 * 1024, // 500MB
        'maxDatabaseSize': 2 * 1024 * 1024 * 1024, // 2GB
      };
    }
  }
  
  static Map<String, dynamic> getAllCapabilities() {
    return {
      'platform': PlatformService.platformName,
      'cache': {
        'fileCache': supportsFileCache,
        'memoryCache': supportsMemoryCache,
        'secureStorage': supportsSecureStorage,
      },
      'downloads': {
        'native': supportsNativeDownloads,
        'browser': supportsBrowserDownloads,
        'background': supportsBackgroundDownloads,
        'notifications': supportsDownloadNotifications,
      },
      'concurrency': {
        'isolates': supportsIsolates,
        'webWorkers': supportsWebWorkers,
        'multiThreading': supportsMultiThreading,
        'recommendedThreads': recommendedThreadCount,
      },
      'storage': {
        'localDatabase': supportsLocalDatabase,
        'fileSystem': supportsFileSystem,
        'directoryAccess': supportsDirectoryAccess,
      },
      'network': {
        'offlineMode': supportsOfflineMode,
        'backgroundSync': supportsBackgroundSync,
        'connectivityCheck': supportsConnectivityCheck,
      },
      'ui': {
        'biometrics': supportsBiometrics,
        'nativeNavigation': supportsNativeNavigation,
        'fullscreen': supportsFullscreen,
        'systemNotifications': supportsSystemNotifications,
      },
      'performance': performanceLimits,
    };
  }
  
  static void debugPrintCapabilities() {
    if (!kDebugMode) return;
    
    final caps = getAllCapabilities();
    debugPrint('=== Platform Capabilities for ${caps['platform']} ===');
    
    caps.forEach((category, features) {
      if (category != 'platform') {
        debugPrint('\n$category:');
        if (features is Map<String, dynamic>) {
          features.forEach((key, value) {
            debugPrint('  $key: $value');
          });
        }
      }
    });
  }
}