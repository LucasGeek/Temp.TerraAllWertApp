import 'package:flutter_test/flutter_test.dart';
import 'package:terra_allwert_app/infra/platform/platform_service.dart';

void main() {
  group('PlatformService', () {
    test('should identify current platform', () {
      final platform = PlatformService.current;
      expect(platform, isA<AppPlatform>());
      expect(PlatformService.platformName, isA<String>());
    });

    test('should correctly identify mobile platforms', () {
      final isMobile = PlatformService.isMobile;
      expect(isMobile, isA<bool>());
      
      if (isMobile) {
        expect(
          PlatformService.current == AppPlatform.android || 
          PlatformService.current == AppPlatform.ios,
          isTrue
        );
      }
    });

    test('should correctly identify desktop platforms', () {
      final isDesktop = PlatformService.isDesktop;
      expect(isDesktop, isA<bool>());
      
      if (isDesktop) {
        expect(
          PlatformService.current == AppPlatform.macos || 
          PlatformService.current == AppPlatform.windows ||
          PlatformService.current == AppPlatform.linux,
          isTrue
        );
      }
    });

    test('should correctly identify web platform', () {
      final isWeb = PlatformService.isWeb;
      expect(isWeb, isA<bool>());
      
      if (isWeb) {
        expect(PlatformService.current, equals(AppPlatform.web));
      }
    });

    test('should provide platform capabilities', () {
      expect(PlatformService.supportsIsolates, isA<bool>());
      expect(PlatformService.supportsFileSystem, isA<bool>());
      expect(PlatformService.supportsBackgroundTasks, isA<bool>());
      expect(PlatformService.supportsBiometrics, isA<bool>());
      expect(PlatformService.supportsNativeDownloads, isA<bool>());
      expect(PlatformService.supportsLocalNotifications, isA<bool>());
    });

    test('should return platform capabilities map', () {
      final capabilities = PlatformService.platformCapabilities;
      
      expect(capabilities, isA<Map<String, String>>());
      expect(capabilities.containsKey('name'), isTrue);
      expect(capabilities.containsKey('isolates'), isTrue);
      expect(capabilities.containsKey('fileSystem'), isTrue);
      expect(capabilities.containsKey('backgroundTasks'), isTrue);
      expect(capabilities.containsKey('biometrics'), isTrue);
      expect(capabilities.containsKey('nativeDownloads'), isTrue);
      expect(capabilities.containsKey('localNotifications'), isTrue);
    });

    test('web platform should have correct limitations', () {
      if (PlatformService.isWeb) {
        expect(PlatformService.supportsIsolates, isFalse);
        expect(PlatformService.supportsFileSystem, isFalse);
        expect(PlatformService.supportsBackgroundTasks, isFalse);
        expect(PlatformService.supportsBiometrics, isFalse);
        expect(PlatformService.supportsNativeDownloads, isFalse);
        expect(PlatformService.supportsLocalNotifications, isFalse);
      }
    });

    test('mobile platforms should support biometrics and background tasks', () {
      if (PlatformService.isMobile) {
        expect(PlatformService.supportsBiometrics, isTrue);
        expect(PlatformService.supportsBackgroundTasks, isTrue);
        expect(PlatformService.supportsNativeDownloads, isTrue);
        expect(PlatformService.supportsLocalNotifications, isTrue);
      }
    });

    test('desktop platforms should support file system and isolates', () {
      if (PlatformService.isDesktop) {
        expect(PlatformService.supportsFileSystem, isTrue);
        expect(PlatformService.supportsIsolates, isTrue);
        expect(PlatformService.supportsNativeDownloads, isTrue);
        expect(PlatformService.supportsLocalNotifications, isTrue);
      }
    });
  });
}