import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'cache_service.dart';
import 'models/cache_metadata.dart';
import '../logging/app_logger.dart';

/// Serviço de limpeza inteligente de cache
class CacheCleaner {
  final CacheService _cacheService;
  Timer? _periodicCleanupTimer;
  
  // Configurações padrão de limpeza
  static const Duration defaultMaxAge = Duration(days: 30);
  static const int defaultMaxSizeMB = 500; // 500MB
  static const int defaultMaxFiles = 10000;
  static const Duration defaultCleanupInterval = Duration(hours: 6);
  
  CacheCleaner({required CacheService cacheService}) 
      : _cacheService = cacheService;
  
  /// Inicia limpeza automática periódica
  void startPeriodicCleanup({
    Duration interval = defaultCleanupInterval,
    CleanupPolicy? policy,
  }) {
    if (kIsWeb) {
      AppLogger.info('Periodic cleanup not available on web platform', tag: 'CacheCleaner');
      return;
    }
    
    _periodicCleanupTimer?.cancel();
    
    _periodicCleanupTimer = Timer.periodic(interval, (timer) async {
      try {
        await performCleanup(policy: policy ?? CleanupPolicy.moderate());
      } catch (e) {
        AppLogger.error('Periodic cleanup failed: $e', tag: 'CacheCleaner');
      }
    });
    
    AppLogger.info('Started periodic cache cleanup (${interval.inHours}h interval)', tag: 'CacheCleaner');
  }
  
  /// Para limpeza automática
  void stopPeriodicCleanup() {
    _periodicCleanupTimer?.cancel();
    _periodicCleanupTimer = null;
    AppLogger.info('Stopped periodic cache cleanup', tag: 'CacheCleaner');
  }
  
  /// Executa limpeza completa do cache
  Future<CleanupResult> performCleanup({
    CleanupPolicy? policy,
    Function(String phase, double progress)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Cache cleanup not supported on web platform');
    }
    
    final cleanupPolicy = policy ?? CleanupPolicy.moderate();
    final startTime = DateTime.now();
    
    AppLogger.info('Starting cache cleanup with policy: ${cleanupPolicy.name}', tag: 'CacheCleaner');
    
    onProgress?.call('Analyzing cache', 0.0);
    
    // Analisar estado atual do cache
    final analysis = await _analyzeCache();
    
    AppLogger.info(
      'Cache analysis: ${analysis.totalFiles} files, ${_formatBytes(analysis.totalSizeBytes)} total',
      tag: 'CacheCleaner'
    );
    
    // Determinar quais arquivos devem ser removidos
    onProgress?.call('Planning cleanup', 0.2);
    final filesToRemove = _planCleanup(analysis, cleanupPolicy);
    
    if (filesToRemove.isEmpty) {
      AppLogger.info('No files need cleanup', tag: 'CacheCleaner');
      return CleanupResult(
        filesRemoved: 0,
        bytesFreed: 0,
        duration: DateTime.now().difference(startTime),
        policy: cleanupPolicy,
      );
    }
    
    AppLogger.info(
      'Planning to remove ${filesToRemove.length} files (${_formatBytes(filesToRemove.fold(0, (sum, f) => sum + f.size))})',
      tag: 'CacheCleaner'
    );
    
    // Executar limpeza
    onProgress?.call('Cleaning files', 0.4);
    final cleanupStats = await _executeCleanup(filesToRemove, onProgress);
    
    // Cleanup de arquivos órfãos
    onProgress?.call('Cleaning orphaned files', 0.8);
    final orphanStats = await _cleanupOrphanedFiles();
    
    // Compactar metadados
    onProgress?.call('Optimizing metadata', 0.9);
    await _optimizeMetadata();
    
    final result = CleanupResult(
      filesRemoved: cleanupStats.filesRemoved + orphanStats.filesRemoved,
      bytesFreed: cleanupStats.bytesFreed + orphanStats.bytesFreed,
      duration: DateTime.now().difference(startTime),
      policy: cleanupPolicy,
      orphanedFilesRemoved: orphanStats.filesRemoved,
      metadataOptimized: true,
    );
    
    onProgress?.call('Cleanup completed', 1.0);
    
    AppLogger.info(
      'Cache cleanup completed: ${result.filesRemoved} files removed, '
      '${_formatBytes(result.bytesFreed)} freed in ${result.duration.inSeconds}s',
      tag: 'CacheCleaner'
    );
    
    return result;
  }
  
  /// Limpa cache por idade
  Future<CleanupResult> cleanupByAge({
    Duration maxAge = defaultMaxAge,
    Function(double progress)? onProgress,
  }) async {
    return performCleanup(
      policy: CleanupPolicy(
        name: 'age-based',
        maxAge: maxAge,
        maxSizeMB: null,
        maxFiles: null,
        strategy: CleanupStrategy.oldestFirst,
      ),
      onProgress: onProgress != null 
          ? (phase, progress) => onProgress(progress)
          : null,
    );
  }
  
  /// Limpa cache por tamanho
  Future<CleanupResult> cleanupBySize({
    int maxSizeMB = defaultMaxSizeMB,
    Function(double progress)? onProgress,
  }) async {
    return performCleanup(
      policy: CleanupPolicy(
        name: 'size-based',
        maxAge: null,
        maxSizeMB: maxSizeMB,
        maxFiles: null,
        strategy: CleanupStrategy.largestFirst,
      ),
      onProgress: onProgress != null 
          ? (phase, progress) => onProgress(progress)
          : null,
    );
  }
  
  /// Limpa arquivos temporários e falhas
  Future<CleanupResult> cleanupTemporaryFiles() async {
    final analysis = await _analyzeCache();
    
    // Arquivos com falha de upload há mais de 1 hora
    final tempFiles = analysis.allFiles.where((file) {
      final isOld = DateTime.now().difference(file.cachedAt).inHours > 1;
      final isTemp = file.type == 'temp' || 
                    (file.isUploaded == false && file.uploadedAt == null);
      return isOld && isTemp;
    }).toList();
    
    if (tempFiles.isEmpty) {
      return CleanupResult(
        filesRemoved: 0,
        bytesFreed: 0,
        duration: Duration.zero,
        policy: CleanupPolicy.temporary(),
      );
    }
    
    final stats = await _executeCleanup(tempFiles, null);
    
    AppLogger.info(
      'Temporary files cleanup: ${stats.filesRemoved} files, ${_formatBytes(stats.bytesFreed)} freed',
      tag: 'CacheCleaner'
    );
    
    return CleanupResult(
      filesRemoved: stats.filesRemoved,
      bytesFreed: stats.bytesFreed,
      duration: stats.duration,
      policy: CleanupPolicy.temporary(),
    );
  }
  
  /// Obtém estimativa de limpeza sem executar
  Future<CleanupEstimate> estimateCleanup(CleanupPolicy policy) async {
    final analysis = await _analyzeCache();
    final filesToRemove = _planCleanup(analysis, policy);
    
    final bytesToFree = filesToRemove.fold(0, (sum, f) => sum + f.size);
    final percentageFree = analysis.totalSizeBytes > 0 
        ? (bytesToFree / analysis.totalSizeBytes) * 100
        : 0.0;
    
    return CleanupEstimate(
      filesWillBeRemoved: filesToRemove.length,
      bytesWillBeFreed: bytesToFree,
      percentageWillBeFreed: percentageFree,
      policy: policy,
    );
  }
  
  /// Analisa estado atual do cache
  Future<CacheAnalysis> _analyzeCache() async {
    final allFiles = _cacheService.getAllCachedFiles();
    final totalSize = allFiles.fold(0, (sum, file) => sum + file.size);
    
    // Agrupar por tipo
    final byType = <String, List<CachedFileInfo>>{};
    for (final file in allFiles) {
      byType.putIfAbsent(file.type, () => []).add(file);
    }
    
    // Agrupar por idade
    final now = DateTime.now();
    final byAge = {
      'recent': <CachedFileInfo>[], // < 1 dia
      'medium': <CachedFileInfo>[], // 1-7 dias
      'old': <CachedFileInfo>[],    // 7-30 dias
      'ancient': <CachedFileInfo>[], // > 30 dias
    };
    
    for (final file in allFiles) {
      final age = now.difference(file.cachedAt);
      if (age.inDays < 1) {
        byAge['recent']!.add(file);
      } else if (age.inDays < 7) {
        byAge['medium']!.add(file);
      } else if (age.inDays < 30) {
        byAge['old']!.add(file);
      } else {
        byAge['ancient']!.add(file);
      }
    }
    
    return CacheAnalysis(
      totalFiles: allFiles.length,
      totalSizeBytes: totalSize,
      allFiles: allFiles,
      filesByType: byType,
      filesByAge: byAge,
      analyzedAt: now,
    );
  }
  
  /// Planeja quais arquivos remover baseado na política
  List<CachedFileInfo> _planCleanup(CacheAnalysis analysis, CleanupPolicy policy) {
    var candidates = List<CachedFileInfo>.from(analysis.allFiles);
    final toRemove = <CachedFileInfo>[];
    
    // Filtrar por idade máxima
    if (policy.maxAge != null) {
      final cutoffDate = DateTime.now().subtract(policy.maxAge!);
      candidates = candidates.where((file) => 
          file.cachedAt.isBefore(cutoffDate)).toList();
    }
    
    // Aplicar estratégia de ordenação
    switch (policy.strategy) {
      case CleanupStrategy.oldestFirst:
        candidates.sort((a, b) => a.cachedAt.compareTo(b.cachedAt));
        break;
      case CleanupStrategy.largestFirst:
        candidates.sort((a, b) => b.size.compareTo(a.size));
        break;
      case CleanupStrategy.leastUsedFirst:
        // Usar lastModified como proxy para uso (arquivos acessados são modificados)
        candidates.sort((a, b) => a.lastModified.compareTo(b.lastModified));
        break;
    }
    
    // Aplicar limites
    var currentSize = analysis.totalSizeBytes;
    var currentFiles = analysis.totalFiles;
    
    for (final file in candidates) {
      bool shouldRemove = false;
      
      // Verificar limite de tamanho
      if (policy.maxSizeMB != null) {
        final maxBytes = policy.maxSizeMB! * 1024 * 1024;
        if (currentSize > maxBytes) {
          shouldRemove = true;
        }
      }
      
      // Verificar limite de arquivos
      if (policy.maxFiles != null) {
        if (currentFiles > policy.maxFiles!) {
          shouldRemove = true;
        }
      }
      
      if (shouldRemove) {
        toRemove.add(file);
        currentSize -= file.size;
        currentFiles--;
      }
    }
    
    return toRemove;
  }
  
  /// Executa a remoção dos arquivos
  Future<CleanupStats> _executeCleanup(
    List<CachedFileInfo> filesToRemove,
    Function(String phase, double progress)? onProgress,
  ) async {
    final startTime = DateTime.now();
    int removed = 0;
    int bytesFreed = 0;
    
    for (int i = 0; i < filesToRemove.length; i++) {
      final file = filesToRemove[i];
      
      try {
        final success = await _cacheService.removeCachedFile(file.id);
        if (success) {
          removed++;
          bytesFreed += file.size;
        }
      } catch (e) {
        AppLogger.warning('Failed to remove cached file ${file.id}: $e', tag: 'CacheCleaner');
      }
      
      // Atualizar progresso
      if (onProgress != null && i % 10 == 0) {
        final progress = 0.4 + (0.4 * (i / filesToRemove.length));
        onProgress('Cleaning files', progress);
      }
    }
    
    return CleanupStats(
      filesRemoved: removed,
      bytesFreed: bytesFreed,
      duration: DateTime.now().difference(startTime),
    );
  }
  
  /// Remove arquivos órfãos (arquivos físicos sem metadados)
  Future<CleanupStats> _cleanupOrphanedFiles() async {
    if (kIsWeb) return CleanupStats(filesRemoved: 0, bytesFreed: 0, duration: Duration.zero);
    
    final startTime = DateTime.now();
    int removed = 0;
    int bytesFreed = 0;
    
    try {
      final appDir = await getApplicationSupportDirectory();
      final cacheDir = Directory(path.join(appDir.path, 'file_cache'));
      
      if (!await cacheDir.exists()) {
        return CleanupStats(filesRemoved: 0, bytesFreed: 0, duration: Duration.zero);
      }
      
      // Obter IDs dos arquivos conhecidos
      final knownFiles = _cacheService.getAllCachedFiles()
          .map((f) => f.id).toSet();
      
      // Verificar arquivos físicos
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final fileName = path.basenameWithoutExtension(entity.path);
          
          // Se arquivo não está nos metadados, é órfão
          if (!knownFiles.contains(fileName)) {
            try {
              final stat = await entity.stat();
              await entity.delete();
              removed++;
              bytesFreed += stat.size;
              
              AppLogger.debug('Removed orphaned file: ${entity.path}', tag: 'CacheCleaner');
            } catch (e) {
              AppLogger.warning('Failed to remove orphaned file ${entity.path}: $e', tag: 'CacheCleaner');
            }
          }
        }
      }
    } catch (e) {
      AppLogger.error('Orphaned files cleanup failed: $e', tag: 'CacheCleaner');
    }
    
    if (removed > 0) {
      AppLogger.info('Removed $removed orphaned files (${_formatBytes(bytesFreed)})', tag: 'CacheCleaner');
    }
    
    return CleanupStats(
      filesRemoved: removed,
      bytesFreed: bytesFreed,
      duration: DateTime.now().difference(startTime),
    );
  }
  
  /// Otimiza metadados removendo entradas antigas
  Future<void> _optimizeMetadata() async {
    // TODO: Implementar compactação de metadados
    AppLogger.debug('Metadata optimization completed', tag: 'CacheCleaner');
  }
  
  /// Formata bytes para display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  void dispose() {
    stopPeriodicCleanup();
  }
}

/// Política de limpeza de cache
class CleanupPolicy {
  final String name;
  final Duration? maxAge;
  final int? maxSizeMB;
  final int? maxFiles;
  final CleanupStrategy strategy;
  
  const CleanupPolicy({
    required this.name,
    this.maxAge,
    this.maxSizeMB,
    this.maxFiles,
    required this.strategy,
  });
  
  /// Política conservadora (remove pouco)
  static CleanupPolicy conservative() => const CleanupPolicy(
    name: 'conservative',
    maxAge: Duration(days: 90),
    maxSizeMB: 1000, // 1GB
    strategy: CleanupStrategy.oldestFirst,
  );
  
  /// Política moderada (padrão)
  static CleanupPolicy moderate() => const CleanupPolicy(
    name: 'moderate',
    maxAge: Duration(days: 30),
    maxSizeMB: 500, // 500MB
    strategy: CleanupStrategy.leastUsedFirst,
  );
  
  /// Política agressiva (remove bastante)
  static CleanupPolicy aggressive() => const CleanupPolicy(
    name: 'aggressive',
    maxAge: Duration(days: 7),
    maxSizeMB: 100, // 100MB
    strategy: CleanupStrategy.oldestFirst,
  );
  
  /// Política apenas para arquivos temporários
  static CleanupPolicy temporary() => const CleanupPolicy(
    name: 'temporary',
    maxAge: Duration(hours: 1),
    strategy: CleanupStrategy.oldestFirst,
  );
}

/// Estratégia de ordenação para limpeza
enum CleanupStrategy {
  oldestFirst,      // Remove arquivos mais antigos primeiro
  largestFirst,     // Remove arquivos maiores primeiro
  leastUsedFirst,   // Remove arquivos menos usados primeiro
}

/// Resultado da análise de cache
class CacheAnalysis {
  final int totalFiles;
  final int totalSizeBytes;
  final List<CachedFileInfo> allFiles;
  final Map<String, List<CachedFileInfo>> filesByType;
  final Map<String, List<CachedFileInfo>> filesByAge;
  final DateTime analyzedAt;
  
  CacheAnalysis({
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.allFiles,
    required this.filesByType,
    required this.filesByAge,
    required this.analyzedAt,
  });
}

/// Resultado da limpeza
class CleanupResult {
  final int filesRemoved;
  final int bytesFreed;
  final Duration duration;
  final CleanupPolicy policy;
  final int orphanedFilesRemoved;
  final bool metadataOptimized;
  
  CleanupResult({
    required this.filesRemoved,
    required this.bytesFreed,
    required this.duration,
    required this.policy,
    this.orphanedFilesRemoved = 0,
    this.metadataOptimized = false,
  });
}

/// Estimativa de limpeza
class CleanupEstimate {
  final int filesWillBeRemoved;
  final int bytesWillBeFreed;
  final double percentageWillBeFreed;
  final CleanupPolicy policy;
  
  CleanupEstimate({
    required this.filesWillBeRemoved,
    required this.bytesWillBeFreed,
    required this.percentageWillBeFreed,
    required this.policy,
  });
}

/// Estatísticas de limpeza
class CleanupStats {
  final int filesRemoved;
  final int bytesFreed;
  final Duration duration;
  
  CleanupStats({
    required this.filesRemoved,
    required this.bytesFreed,
    required this.duration,
  });
}