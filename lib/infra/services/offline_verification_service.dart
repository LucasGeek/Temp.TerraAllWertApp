import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../platform/platform_service.dart';
import '../network/connectivity_service.dart';
import '../cache/media_cache_service.dart';
import '../cache/cache_manager.dart';
import '../logging/app_logger.dart';

/// Service para verificação completa de capacidades offline
/// Garante que mobile e desktop funcionem sem internet
/// Ignora web conforme solicitado
class OfflineVerificationService {
  final ConnectivityService _connectivityService;
  final MediaCacheService _mediaCacheService;
  final CacheManager _cacheManager;
  
  OfflineVerificationService(
    this._connectivityService,
    this._mediaCacheService,
    this._cacheManager,
  );
  
  /// Inicializa verificação offline completa
  Future<void> initialize() async {
    try {
      // Para web, não faz verificação offline
      if (PlatformService.isWeb) {
        NetworkLogger.info('Web platform: offline verification skipped');
        return;
      }
      
      NetworkLogger.info('Initializing offline verification for ${PlatformService.platformName}');
      
      // Inicializa serviços de conectividade e cache
      await _connectivityService.initialize();
      await _mediaCacheService.initialize();
      await _cacheManager.initialize();
      
      // Executa verificação inicial
      final verification = await performOfflineVerification();
      
      NetworkLogger.info('Offline verification completed: ${verification.isFullyOfflineCapable ? 'READY' : 'PARTIAL'}');
      
      if (!verification.isFullyOfflineCapable) {
        NetworkLogger.warning('Offline capabilities limited: ${verification.issues.join(', ')}');
      }
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to initialize offline verification', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Executa verificação completa de capacidades offline
  Future<OfflineVerificationResult> performOfflineVerification() async {
    try {
      // Para web, sempre retorna não suportado
      if (PlatformService.isWeb) {
        return OfflineVerificationResult(
          isFullyOfflineCapable: false,
          platformSupported: false,
          hasFileSystemAccess: false,
          hasCacheSystem: false,
          connectivityMonitoring: false,
          localStorageWorking: false,
          cacheStats: CacheStats(totalItems: 0, totalSize: 0, imagesCount: 0, videosCount: 0, documentsCount: 0),
          issues: ['Web platform not supported for offline operation'],
        );
      }
      
      NetworkLogger.info('Performing comprehensive offline verification');
      
      final issues = <String>[];
      
      // 1. Verifica suporte de plataforma
      final platformSupported = PlatformService.isMobile || PlatformService.isDesktop;
      if (!platformSupported) {
        issues.add('Platform ${PlatformService.platformName} not supported');
      }
      
      // 2. Verifica acesso ao sistema de arquivos
      final hasFileSystemAccess = await _verifyFileSystemAccess();
      if (!hasFileSystemAccess) {
        issues.add('File system access not available');
      }
      
      // 3. Verifica sistema de cache
      final hasCacheSystem = await _verifyCacheSystem();
      if (!hasCacheSystem) {
        issues.add('Cache system not working');
      }
      
      // 4. Verifica monitoramento de conectividade
      final connectivityMonitoring = await _verifyConnectivityMonitoring();
      if (!connectivityMonitoring) {
        issues.add('Connectivity monitoring not available');
      }
      
      // 5. Verifica armazenamento local
      final localStorageWorking = await _verifyLocalStorage();
      if (!localStorageWorking) {
        issues.add('Local storage not working');
      }
      
      // 6. Obtém estatísticas do cache
      final cacheStats = await _mediaCacheService.getCacheStats();
      
      final isFullyOfflineCapable = platformSupported &&
          hasFileSystemAccess &&
          hasCacheSystem &&
          connectivityMonitoring &&
          localStorageWorking;
      
      NetworkLogger.info('Offline verification results:');
      NetworkLogger.info('- Platform supported: $platformSupported');
      NetworkLogger.info('- File system access: $hasFileSystemAccess');
      NetworkLogger.info('- Cache system: $hasCacheSystem');
      NetworkLogger.info('- Connectivity monitoring: $connectivityMonitoring');
      NetworkLogger.info('- Local storage: $localStorageWorking');
      NetworkLogger.info('- Cache stats: ${cacheStats.totalItems} items, ${cacheStats.totalSizeFormatted}');
      NetworkLogger.info('- Fully offline capable: $isFullyOfflineCapable');
      
      return OfflineVerificationResult(
        isFullyOfflineCapable: isFullyOfflineCapable,
        platformSupported: platformSupported,
        hasFileSystemAccess: hasFileSystemAccess,
        hasCacheSystem: hasCacheSystem,
        connectivityMonitoring: connectivityMonitoring,
        localStorageWorking: localStorageWorking,
        cacheStats: cacheStats,
        issues: issues,
      );
    } catch (e, stackTrace) {
      NetworkLogger.error('Offline verification failed', error: e, stackTrace: stackTrace);
      
      return OfflineVerificationResult(
        isFullyOfflineCapable: false,
        platformSupported: false,
        hasFileSystemAccess: false,
        hasCacheSystem: false,
        connectivityMonitoring: false,
        localStorageWorking: false,
        cacheStats: CacheStats(totalItems: 0, totalSize: 0, imagesCount: 0, videosCount: 0, documentsCount: 0),
        issues: ['Verification process failed: ${e.toString()}'],
      );
    }
  }
  
  /// Prepara aplicação para uso offline
  Future<OfflinePreparationResult> prepareForOfflineUse({
    List<String> urlsToPrecache = const [],
    bool clearOldCache = false,
  }) async {
    try {
      if (PlatformService.isWeb) {
        return OfflinePreparationResult(
          success: false,
          precachedItems: 0,
          cacheCleared: false,
          totalCacheSize: 0,
          error: 'Web platform not supported',
        );
      }
      
      NetworkLogger.info('Preparing application for offline use');
      
      int precachedItems = 0;
      bool cacheCleared = false;
      
      // Limpa cache antigo se solicitado
      if (clearOldCache) {
        await _mediaCacheService.clearCache();
        await _cacheManager.clearCache();
        cacheCleared = true;
        NetworkLogger.info('Old cache cleared');
      }
      
      // Pré-cacheia URLs fornecidas
      if (urlsToPrecache.isNotEmpty) {
        await _mediaCacheService.preCacheUrls(urlsToPrecache);
        precachedItems = urlsToPrecache.length;
        NetworkLogger.info('Pre-cached $precachedItems URLs');
      }
      
      // Verifica tamanho total do cache
      final cacheStats = await _mediaCacheService.getCacheStats();
      final totalCacheSize = cacheStats.totalSize;
      
      NetworkLogger.info('Offline preparation completed: $precachedItems items pre-cached, ${cacheStats.totalSizeFormatted} total cache');
      
      return OfflinePreparationResult(
        success: true,
        precachedItems: precachedItems,
        cacheCleared: cacheCleared,
        totalCacheSize: totalCacheSize,
      );
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to prepare for offline use', error: e, stackTrace: stackTrace);
      
      return OfflinePreparationResult(
        success: false,
        precachedItems: 0,
        cacheCleared: false,
        totalCacheSize: 0,
        error: e.toString(),
      );
    }
  }
  
  /// Verifica se URL está disponível offline
  Future<bool> isAvailableOffline(String url) async {
    if (PlatformService.isWeb) return false;
    
    try {
      // Verifica cache de mídia
      final isCached = _mediaCacheService.isCached(url);
      if (isCached) return true;
      
      // Verifica cache geral
      final cachedData = await _cacheManager.getCachedData(url);
      return cachedData != null;
    } catch (e) {
      NetworkLogger.warning('Failed to check offline availability for: $url', error: e);
      return false;
    }
  }
  
  /// Obtém estatísticas detalhadas do sistema offline
  Future<OfflineSystemStats> getOfflineSystemStats() async {
    try {
      if (PlatformService.isWeb) {
        return OfflineSystemStats(
          totalCacheSize: 0,
          mediaItems: 0,
          dataItems: 0,
          queryItems: 0,
          isOnline: true,
          lastConnectivityCheck: DateTime.now(),
        );
      }
      
      final cacheStats = await _mediaCacheService.getCacheStats();
      final cacheSize = await _cacheManager.getCacheSize();
      final cachedKeys = await _cacheManager.getCachedKeys();
      
      final dataItems = cachedKeys.where((k) => k.startsWith('data:')).length;
      final queryItems = cachedKeys.where((k) => k.startsWith('query:')).length;
      
      return OfflineSystemStats(
        totalCacheSize: cacheStats.totalSize + cacheSize,
        mediaItems: cacheStats.totalItems,
        dataItems: dataItems,
        queryItems: queryItems,
        isOnline: _connectivityService.isOnline,
        lastConnectivityCheck: DateTime.now(),
      );
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to get offline system stats', error: e, stackTrace: stackTrace);
      
      return OfflineSystemStats(
        totalCacheSize: 0,
        mediaItems: 0,
        dataItems: 0,
        queryItems: 0,
        isOnline: false,
        lastConnectivityCheck: DateTime.now(),
      );
    }
  }
  
  // Métodos privados de verificação
  
  Future<bool> _verifyFileSystemAccess() async {
    try {
      if (!PlatformService.supportsFileSystem) return false;
      
      final testFile = File('/tmp/terra_allwert_test_${DateTime.now().millisecondsSinceEpoch}.txt');
      await testFile.writeAsString('test');
      final exists = await testFile.exists();
      if (exists) await testFile.delete();
      
      return exists;
    } catch (e) {
      NetworkLogger.debug('File system access test failed', error: e);
      return false;
    }
  }
  
  Future<bool> _verifyCacheSystem() async {
    try {
      await _cacheManager.cacheData('test_key', {'test': 'value'});
      final cachedData = await _cacheManager.getCachedData('test_key');
      return cachedData != null;
    } catch (e) {
      NetworkLogger.debug('Cache system test failed', error: e);
      return false;
    }
  }
  
  Future<bool> _verifyConnectivityMonitoring() async {
    try {
      await _connectivityService.checkConnectivity();
      return true; // Se chegou até aqui, o monitoramento está funcionando
    } catch (e) {
      NetworkLogger.debug('Connectivity monitoring test failed', error: e);
      return false;
    }
  }
  
  Future<bool> _verifyLocalStorage() async {
    try {
      // Testa GetStorage indiretamente através do cache
      await _cacheManager.cacheData('storage_test', {'timestamp': DateTime.now().toIso8601String()});
      final data = await _cacheManager.getCachedData('storage_test');
      return data != null;
    } catch (e) {
      NetworkLogger.debug('Local storage test failed', error: e);
      return false;
    }
  }
}

/// Resultado da verificação offline
class OfflineVerificationResult {
  final bool isFullyOfflineCapable;
  final bool platformSupported;
  final bool hasFileSystemAccess;
  final bool hasCacheSystem;
  final bool connectivityMonitoring;
  final bool localStorageWorking;
  final CacheStats cacheStats;
  final List<String> issues;
  
  OfflineVerificationResult({
    required this.isFullyOfflineCapable,
    required this.platformSupported,
    required this.hasFileSystemAccess,
    required this.hasCacheSystem,
    required this.connectivityMonitoring,
    required this.localStorageWorking,
    required this.cacheStats,
    required this.issues,
  });
}

/// Resultado da preparação offline
class OfflinePreparationResult {
  final bool success;
  final int precachedItems;
  final bool cacheCleared;
  final int totalCacheSize;
  final String? error;
  
  OfflinePreparationResult({
    required this.success,
    required this.precachedItems,
    required this.cacheCleared,
    required this.totalCacheSize,
    this.error,
  });
}

/// Estatísticas do sistema offline
class OfflineSystemStats {
  final int totalCacheSize;
  final int mediaItems;
  final int dataItems;
  final int queryItems;
  final bool isOnline;
  final DateTime lastConnectivityCheck;
  
  OfflineSystemStats({
    required this.totalCacheSize,
    required this.mediaItems,
    required this.dataItems,
    required this.queryItems,
    required this.isOnline,
    required this.lastConnectivityCheck,
  });
  
  String get totalCacheSizeFormatted {
    if (totalCacheSize < 1024) return '${totalCacheSize}B';
    if (totalCacheSize < 1024 * 1024) return '${(totalCacheSize / 1024).toStringAsFixed(1)}KB';
    return '${(totalCacheSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  
  int get totalItems => mediaItems + dataItems + queryItems;
}

final offlineVerificationServiceProvider = Provider<OfflineVerificationService>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  final mediaCacheService = ref.watch(mediaCacheServiceProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  
  return OfflineVerificationService(connectivityService, mediaCacheService, cacheManager);
});

final offlineVerificationServiceInitProvider = FutureProvider<void>((ref) async {
  final offlineVerificationService = ref.watch(offlineVerificationServiceProvider);
  await offlineVerificationService.initialize();
});

final offlineVerificationResultProvider = FutureProvider<OfflineVerificationResult>((ref) async {
  final offlineVerificationService = ref.watch(offlineVerificationServiceProvider);
  return await offlineVerificationService.performOfflineVerification();
});

final offlineSystemStatsProvider = FutureProvider<OfflineSystemStats>((ref) async {
  final offlineVerificationService = ref.watch(offlineVerificationServiceProvider);
  return await offlineVerificationService.getOfflineSystemStats();
});