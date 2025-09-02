import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';
import 'models/cache_metadata.dart';
import 'file_lifecycle_manager.dart';
import 'cache_service.dart';

/// Serviço de cache aprimorado com gerenciamento de ciclo de vida
class EnhancedCacheService extends CacheService {
  final FileLifecycleManager _lifecycleManager;
  
  EnhancedCacheService({
    required FileLifecycleManager lifecycleManager,
  }) : _lifecycleManager = lifecycleManager;

  @override
  Future<void> initialize() async {
    await super.initialize();
    await _lifecycleManager.initialize();
    AppLogger.info('EnhancedCacheService initialized with lifecycle management', tag: 'EnhancedCache');
  }

  /// Cache arquivo com metadados de ciclo de vida
  Future<CachedFileInfo> cacheFileWithLifecycle({
    required String fileId,
    required Uint8List bytes,
    required String originalPath,
    required String type,
    required String entityId,
    required String entityType,
    RetentionPolicy retentionPolicy = RetentionPolicy.timeBased,
    Duration? customRetention,
    Map<String, dynamic>? customMetadata,
  }) async {
    try {
      // Cache o arquivo normalmente primeiro
      final cachedInfo = await super.cacheFile(
        fileId: fileId,
        bytes: bytes,
        originalPath: originalPath,
        type: type,
      );

      // Registrar no gerenciador de ciclo de vida
      await _lifecycleManager.registerFile(
        entityId: entityId,
        entityType: entityType,
        filePath: cachedInfo.localPath,
        fileSize: bytes.length,
        policy: retentionPolicy,
        customRetention: customRetention,
        customMetadata: {
          'originalPath': originalPath,
          'type': type,
          'checksum': cachedInfo.checksum,
          ...?customMetadata,
        },
      );

      AppLogger.info(
        'File cached with lifecycle: $fileId for $entityType:$entityId',
        tag: 'EnhancedCache',
      );

      return cachedInfo;
    } catch (e) {
      AppLogger.error('Failed to cache file with lifecycle: $e', tag: 'EnhancedCache');
      rethrow;
    }
  }

  /// Obtém arquivo do cache com tracking de acesso
  @override
  Future<Uint8List?> getCachedFile(String fileId) async {
    try {
      // Usar o lifecycle manager para acessar o arquivo
      final file = await _lifecycleManager.accessFile(fileId);
      
      if (file != null && await file.exists()) {
        final bytes = await file.readAsBytes();
        AppLogger.debug('File accessed via lifecycle manager: $fileId', tag: 'EnhancedCache');
        return bytes;
      }

      // Fallback para o método padrão se não estiver no lifecycle manager
      return await super.getCachedFile(fileId);
    } catch (e) {
      AppLogger.error('Failed to get cached file: $e', tag: 'EnhancedCache');
      return null;
    }
  }

  /// Remove arquivo do cache com cleanup de ciclo de vida
  @override
  Future<bool> removeCachedFile(String fileId) async {
    try {
      // Remover via lifecycle manager primeiro
      final lifecycleRemoved = await _lifecycleManager.removeFile(fileId);
      
      // Depois via cache service padrão
      final cacheRemoved = await super.removeCachedFile(fileId);
      
      AppLogger.info('File removed: $fileId (lifecycle: $lifecycleRemoved, cache: $cacheRemoved)', tag: 'EnhancedCache');
      return lifecycleRemoved || cacheRemoved;
    } catch (e) {
      AppLogger.error('Failed to remove cached file: $e', tag: 'EnhancedCache');
      return false;
    }
  }

  /// Remove todos os arquivos de uma entidade
  Future<int> removeEntityFiles(String entityId, String entityType) async {
    try {
      final removedCount = await _lifecycleManager.removeEntityFiles(entityId, entityType);
      AppLogger.info('Removed $removedCount files for $entityType:$entityId', tag: 'EnhancedCache');
      return removedCount;
    } catch (e) {
      AppLogger.error('Failed to remove entity files: $e', tag: 'EnhancedCache');
      return 0;
    }
  }

  /// Atualiza política de retenção de arquivos de uma entidade
  Future<void> updateEntityRetentionPolicy(
    String entityId,
    String entityType,
    RetentionPolicy newPolicy, {
    Duration? customRetention,
  }) async {
    try {
      final entityFiles = _lifecycleManager.getEntityFiles(entityId, entityType);
      
      for (final fileMetadata in entityFiles) {
        await _lifecycleManager.updateRetentionPolicy(
          fileMetadata.fileId,
          newPolicy,
          customRetention: customRetention,
        );
      }
      
      AppLogger.info(
        'Updated retention policy for ${entityFiles.length} files of $entityType:$entityId to $newPolicy',
        tag: 'EnhancedCache',
      );
    } catch (e) {
      AppLogger.error('Failed to update retention policy: $e', tag: 'EnhancedCache');
    }
  }

  /// Executa limpeza automática
  Future<CleanupResult> performCleanup({bool force = false}) async {
    try {
      return await _lifecycleManager.performCleanup(force: force);
    } catch (e) {
      AppLogger.error('Failed to perform cleanup: $e', tag: 'EnhancedCache');
      return CleanupResult(
        removedCount: 0,
        freedBytes: 0,
        expiredFiles: 0,
        unusedFiles: 0,
        oversizedFiles: 0,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Obtém estatísticas detalhadas do cache
  Future<DetailedCacheStatistics> getDetailedStatistics() async {
    try {
      final lifecycleStats = _lifecycleManager.getStatistics();
      final baseStats = super.getCacheStats();
      
      return DetailedCacheStatistics(
        // Stats do cache base
        totalCachedFiles: (baseStats['totalFiles'] ?? 0) as int,
        totalCacheSize: (baseStats['totalSize'] ?? 0) as int,
        cacheHitRate: baseStats['hitRate'] ?? 0.0,
        
        // Stats do lifecycle
        lifecycleStats: lifecycleStats,
        
        // Stats combinadas
        combinedTotalFiles: lifecycleStats.totalFiles + ((baseStats['totalFiles'] ?? 0) as int),
        combinedTotalSize: lifecycleStats.totalSizeBytes + ((baseStats['totalSize'] ?? 0) as int),
        
        // Distribuição por entidade/tipo
        filesByEntity: lifecycleStats.filesByEntity,
        filesByType: lifecycleStats.filesByType,
        filesByPolicy: lifecycleStats.filesByPolicy,
      );
    } catch (e) {
      AppLogger.error('Failed to get detailed statistics: $e', tag: 'EnhancedCache');
      rethrow;
    }
  }

  /// Obtém arquivos de uma entidade específica
  List<FileLifecycleMetadata> getEntityFiles(String entityId, String entityType) {
    return _lifecycleManager.getEntityFiles(entityId, entityType);
  }

  /// Métodos de conveniência para diferentes tipos de entidade

  // PinMapPresentation
  Future<CachedFileInfo> cachePinMapFile({
    required String fileId,
    required Uint8List bytes,
    required String originalPath,
    required String routeId,
    required String pinId,
    RetentionPolicy policy = RetentionPolicy.usageBased,
  }) async {
    return await cacheFileWithLifecycle(
      fileId: fileId,
      bytes: bytes,
      originalPath: originalPath,
      type: 'image',
      entityId: '$routeId:$pinId',
      entityType: 'pin_map',
      retentionPolicy: policy,
      customMetadata: {'routeId': routeId, 'pinId': pinId},
    );
  }

  // ImageCarouselPresentation  
  Future<CachedFileInfo> cacheCarouselFile({
    required String fileId,
    required Uint8List bytes,
    required String originalPath,
    required String type,
    required String routeId,
    RetentionPolicy policy = RetentionPolicy.timeBased,
  }) async {
    return await cacheFileWithLifecycle(
      fileId: fileId,
      bytes: bytes,
      originalPath: originalPath,
      type: type,
      entityId: routeId,
      entityType: 'carousel',
      retentionPolicy: policy,
      customRetention: const Duration(days: 60), // Carousels mantidos por mais tempo
    );
  }

  // FloorPlanPresentation
  Future<CachedFileInfo> cacheFloorPlanFile({
    required String fileId,
    required Uint8List bytes,
    required String originalPath,
    required String routeId,
    required String? floorId,
    required String? apartmentId,
    RetentionPolicy policy = RetentionPolicy.permanent,
  }) async {
    String entityId;
    if (apartmentId != null) {
      entityId = '$routeId:apartment:$apartmentId';
    } else if (floorId != null) {
      entityId = '$routeId:floor:$floorId';
    } else {
      entityId = routeId;
    }

    return await cacheFileWithLifecycle(
      fileId: fileId,
      bytes: bytes,
      originalPath: originalPath,
      type: 'image',
      entityId: entityId,
      entityType: 'floor_plan',
      retentionPolicy: policy,
      customMetadata: {
        'routeId': routeId,
        'floorId': floorId,
        'apartmentId': apartmentId,
      },
    );
  }

  // Método de cleanup por tipo de entidade
  Future<void> cleanupByEntityType(String entityType, {Duration? olderThan}) async {
    try {
      final allFiles = _lifecycleManager.getStatistics().filesByEntity;
      
      for (final entityId in allFiles.keys) {
        final files = _lifecycleManager.getEntityFiles(entityId, entityType);
        
        for (final file in files) {
          if (olderThan != null) {
            final age = DateTime.now().difference(file.lastAccessedAt);
            if (age > olderThan) {
              await _lifecycleManager.removeFile(file.fileId);
            }
          }
        }
      }
      
      AppLogger.info('Cleanup completed for entity type: $entityType', tag: 'EnhancedCache');
    } catch (e) {
      AppLogger.error('Failed to cleanup by entity type: $e', tag: 'EnhancedCache');
    }
  }
}

/// Estatísticas detalhadas combinando cache base e lifecycle
class DetailedCacheStatistics {
  final int totalCachedFiles;
  final int totalCacheSize;
  final double cacheHitRate;
  
  final CacheStatistics lifecycleStats;
  
  final int combinedTotalFiles;
  final int combinedTotalSize;
  
  final Map<String, int> filesByEntity;
  final Map<String, int> filesByType;
  final Map<RetentionPolicy, int> filesByPolicy;

  DetailedCacheStatistics({
    required this.totalCachedFiles,
    required this.totalCacheSize,
    required this.cacheHitRate,
    required this.lifecycleStats,
    required this.combinedTotalFiles,
    required this.combinedTotalSize,
    required this.filesByEntity,
    required this.filesByType,
    required this.filesByPolicy,
  });

  String get formattedCombinedSize => '${combinedTotalSize ~/ (1024 * 1024)} MB';
  
  double get storageEfficiency => 
      totalCachedFiles > 0 ? (lifecycleStats.totalFiles / totalCachedFiles) : 0.0;

  @override
  String toString() => 'DetailedCacheStatistics('
      'files: $combinedTotalFiles, '
      'size: $formattedCombinedSize, '
      'hitRate: ${(cacheHitRate * 100).toStringAsFixed(1)}%, '
      'efficiency: ${(storageEfficiency * 100).toStringAsFixed(1)}%'
      ')';
}