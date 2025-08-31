import 'package:flutter_test/flutter_test.dart';
import 'package:terra_allwert_app/core/infra/platform/platform_capabilities.dart';

void main() {
  group('PlatformCapabilities', () {
    test('should provide cache capabilities', () {
      expect(PlatformCapabilities.supportsFileCache, isA<bool>());
      expect(PlatformCapabilities.supportsMemoryCache, isTrue);
      expect(PlatformCapabilities.supportsSecureStorage, isA<bool>());
    });

    test('should provide download capabilities', () {
      expect(PlatformCapabilities.supportsNativeDownloads, isA<bool>());
      expect(PlatformCapabilities.supportsBrowserDownloads, isA<bool>());
      expect(PlatformCapabilities.supportsBackgroundDownloads, isA<bool>());
      expect(PlatformCapabilities.supportsDownloadNotifications, isA<bool>());
    });

    test('should provide concurrency capabilities', () {
      expect(PlatformCapabilities.supportsIsolates, isA<bool>());
      expect(PlatformCapabilities.supportsWebWorkers, isA<bool>());
      expect(PlatformCapabilities.supportsMultiThreading, isA<bool>());
      expect(PlatformCapabilities.recommendedThreadCount, greaterThan(0));
    });

    test('should provide storage capabilities', () {
      expect(PlatformCapabilities.supportsLocalDatabase, isTrue);
      expect(PlatformCapabilities.supportsFileSystem, isA<bool>());
      expect(PlatformCapabilities.supportsDirectoryAccess, isA<bool>());
    });

    test('should provide network capabilities', () {
      expect(PlatformCapabilities.supportsOfflineMode, isTrue);
      expect(PlatformCapabilities.supportsBackgroundSync, isA<bool>());
      expect(PlatformCapabilities.supportsConnectivityCheck, isTrue);
    });

    test('should provide UI capabilities', () {
      expect(PlatformCapabilities.supportsBiometrics, isA<bool>());
      expect(PlatformCapabilities.supportsNativeNavigation, isA<bool>());
      expect(PlatformCapabilities.supportsFullscreen, isTrue);
      expect(PlatformCapabilities.supportsSystemNotifications, isA<bool>());
    });

    test('should provide performance limits', () {
      final limits = PlatformCapabilities.performanceLimits;
      
      expect(limits, isA<Map<String, int>>());
      expect(limits.containsKey('maxConcurrentDownloads'), isTrue);
      expect(limits.containsKey('maxCacheSize'), isTrue);
      expect(limits.containsKey('maxImageCacheSize'), isTrue);
      expect(limits.containsKey('maxDatabaseSize'), isTrue);
      
      expect(limits['maxConcurrentDownloads']!, greaterThan(0));
      expect(limits['maxCacheSize']!, greaterThan(0));
      expect(limits['maxImageCacheSize']!, greaterThan(0));
      expect(limits['maxDatabaseSize']!, greaterThan(0));
    });

    test('should return all capabilities', () {
      final capabilities = PlatformCapabilities.getAllCapabilities();
      
      expect(capabilities, isA<Map<String, dynamic>>());
      expect(capabilities.containsKey('platform'), isTrue);
      expect(capabilities.containsKey('cache'), isTrue);
      expect(capabilities.containsKey('downloads'), isTrue);
      expect(capabilities.containsKey('concurrency'), isTrue);
      expect(capabilities.containsKey('storage'), isTrue);
      expect(capabilities.containsKey('network'), isTrue);
      expect(capabilities.containsKey('ui'), isTrue);
      expect(capabilities.containsKey('performance'), isTrue);
    });

    test('performance limits should be platform appropriate', () {
      final limits = PlatformCapabilities.performanceLimits;
      
      // Web should have lower limits
      // Mobile should have medium limits
      // Desktop should have higher limits
      final maxDownloads = limits['maxConcurrentDownloads']!;
      expect(maxDownloads, inInclusiveRange(1, 20));
      
      final cacheSize = limits['maxCacheSize']!;
      expect(cacheSize, greaterThan(10 * 1024 * 1024)); // At least 10MB
    });

    test('should not throw when calling debugPrintCapabilities', () {
      expect(() => PlatformCapabilities.debugPrintCapabilities(), returnsNormally);
    });
  });
}