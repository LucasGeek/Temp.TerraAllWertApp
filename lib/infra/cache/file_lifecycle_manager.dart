import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';

/// Políticas de retenção de arquivos
enum RetentionPolicy {
  /// Mantém arquivos por tempo determinado
  timeBased,
  /// Mantém arquivos baseado em uso
  usageBased,
  /// Mantém arquivos baseado em tamanho total do cache
  sizeBased,
  /// Mantém arquivos permanentemente (manual cleanup only)
  permanent,
}

/// Metadados de arquivo para gerenciamento de ciclo de vida
class FileLifecycleMetadata {
  final String fileId;
  final String entityId; // ID da entidade (torre, apartamento, etc)
  final String entityType; // Tipo da entidade (tower, apartment, pin, etc)
  final String filePath;
  final int fileSize;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final DateTime? expiresAt;
  final int accessCount;
  final RetentionPolicy policy;
  final Map<String, dynamic> customMetadata;

  FileLifecycleMetadata({
    required this.fileId,
    required this.entityId,
    required this.entityType,
    required this.filePath,
    required this.fileSize,
    required this.createdAt,
    required this.lastAccessedAt,
    this.expiresAt,
    required this.accessCount,
    required this.policy,
    this.customMetadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'entityId': entityId,
    'entityType': entityType,
    'filePath': filePath,
    'fileSize': fileSize,
    'createdAt': createdAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'accessCount': accessCount,
    'policy': policy.toString(),
    'customMetadata': customMetadata,
  };

  factory FileLifecycleMetadata.fromJson(Map<String, dynamic> json) => FileLifecycleMetadata(
    fileId: json['fileId'] as String,
    entityId: json['entityId'] as String,
    entityType: json['entityType'] as String,
    filePath: json['filePath'] as String,
    fileSize: json['fileSize'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    accessCount: json['accessCount'] as int,
    policy: RetentionPolicy.values.firstWhere(
      (p) => p.toString() == json['policy'],
      orElse: () => RetentionPolicy.timeBased,
    ),
    customMetadata: json['customMetadata'] as Map<String, dynamic>? ?? {},
  );

  FileLifecycleMetadata copyWith({
    DateTime? lastAccessedAt,
    DateTime? expiresAt,
    int? accessCount,
    RetentionPolicy? policy,
    Map<String, dynamic>? customMetadata,
  }) => FileLifecycleMetadata(
    fileId: fileId,
    entityId: entityId,
    entityType: entityType,
    filePath: filePath,
    fileSize: fileSize,
    createdAt: createdAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    accessCount: accessCount ?? this.accessCount,
    policy: policy ?? this.policy,
    customMetadata: customMetadata ?? this.customMetadata,
  );
}

/// Configuração de políticas de retenção
class RetentionConfiguration {
  /// Tempo padrão de retenção para arquivos time-based
  final Duration defaultRetentionPeriod;
  
  /// Número mínimo de acessos para manter arquivo (usage-based)
  final int minimumAccessCount;
  
  /// Tamanho máximo do cache em bytes (size-based)
  final int maxCacheSizeBytes;
  
  /// Intervalo para executar limpeza automática
  final Duration cleanupInterval;
  
  /// Manter arquivos recentemente usados por este período
  final Duration recentUsagePeriod;

  const RetentionConfiguration({
    this.defaultRetentionPeriod = const Duration(days: 30),
    this.minimumAccessCount = 3,
    this.maxCacheSizeBytes = 500 * 1024 * 1024, // 500MB
    this.cleanupInterval = const Duration(hours: 24),
    this.recentUsagePeriod = const Duration(days: 7),
  });
}

/// Gerenciador de ciclo de vida de arquivos
class FileLifecycleManager {
  static const String _metadataKey = 'file_lifecycle_metadata';
  static const String _lastCleanupKey = 'last_cleanup_timestamp';
  
  final RetentionConfiguration _config;
  final Map<String, FileLifecycleMetadata> _fileRegistry = {};
  Timer? _cleanupTimer;
  Directory? _cacheDir;
  
  FileLifecycleManager({
    RetentionConfiguration? config,
  }) : _config = config ?? const RetentionConfiguration();

  /// Inicializa o gerenciador
  Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        final appDir = await getApplicationSupportDirectory();
        _cacheDir = Directory(path.join(appDir.path, 'managed_cache'));
        
        if (!await _cacheDir!.exists()) {
          await _cacheDir!.create(recursive: true);
        }
      }
      
      await _loadMetadata();
      _startCleanupTimer();
      
      AppLogger.info('FileLifecycleManager initialized', tag: 'FileLifecycle');
    } catch (e) {
      AppLogger.error('Failed to initialize FileLifecycleManager: $e', tag: 'FileLifecycle');
    }
  }

  /// Registra um novo arquivo no sistema
  Future<String> registerFile({
    required String entityId,
    required String entityType,
    required String filePath,
    required int fileSize,
    RetentionPolicy policy = RetentionPolicy.timeBased,
    Duration? customRetention,
    Map<String, dynamic>? customMetadata,
  }) async {
    try {
      // Gerar ID único baseado na entidade e tipo
      final fileId = _generateFileId(entityId, entityType, filePath);
      
      final now = DateTime.now();
      DateTime? expiresAt;
      
      if (policy == RetentionPolicy.timeBased) {
        final retention = customRetention ?? _config.defaultRetentionPeriod;
        expiresAt = now.add(retention);
      }
      
      final metadata = FileLifecycleMetadata(
        fileId: fileId,
        entityId: entityId,
        entityType: entityType,
        filePath: filePath,
        fileSize: fileSize,
        createdAt: now,
        lastAccessedAt: now,
        expiresAt: expiresAt,
        accessCount: 1,
        policy: policy,
        customMetadata: customMetadata ?? {},
      );
      
      _fileRegistry[fileId] = metadata;
      await _saveMetadata();
      
      AppLogger.info('File registered: $fileId for $entityType:$entityId', tag: 'FileLifecycle');
      return fileId;
      
    } catch (e) {
      AppLogger.error('Failed to register file: $e', tag: 'FileLifecycle');
      rethrow;
    }
  }

  /// Acessa um arquivo, atualizando metadados de uso
  Future<File?> accessFile(String fileId) async {
    try {
      final metadata = _fileRegistry[fileId];
      if (metadata == null) {
        AppLogger.warning('File not found in registry: $fileId', tag: 'FileLifecycle');
        return null;
      }
      
      final file = File(metadata.filePath);
      if (!await file.exists()) {
        AppLogger.warning('File missing on disk: $fileId', tag: 'FileLifecycle');
        _fileRegistry.remove(fileId);
        await _saveMetadata();
        return null;
      }
      
      // Atualizar metadados de acesso
      _fileRegistry[fileId] = metadata.copyWith(
        lastAccessedAt: DateTime.now(),
        accessCount: metadata.accessCount + 1,
      );
      await _saveMetadata();
      
      AppLogger.debug('File accessed: $fileId (count: ${metadata.accessCount + 1})', tag: 'FileLifecycle');
      return file;
      
    } catch (e) {
      AppLogger.error('Failed to access file $fileId: $e', tag: 'FileLifecycle');
      return null;
    }
  }

  /// Remove arquivo específico
  Future<bool> removeFile(String fileId) async {
    try {
      final metadata = _fileRegistry[fileId];
      if (metadata == null) {
        return false;
      }
      
      final file = File(metadata.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      _fileRegistry.remove(fileId);
      await _saveMetadata();
      
      AppLogger.info('File removed: $fileId', tag: 'FileLifecycle');
      return true;
      
    } catch (e) {
      AppLogger.error('Failed to remove file $fileId: $e', tag: 'FileLifecycle');
      return false;
    }
  }

  /// Remove todos os arquivos de uma entidade
  Future<int> removeEntityFiles(String entityId, String entityType) async {
    try {
      final filesToRemove = _fileRegistry.entries
          .where((entry) => 
              entry.value.entityId == entityId && 
              entry.value.entityType == entityType)
          .map((entry) => entry.key)
          .toList();
      
      int removedCount = 0;
      for (final fileId in filesToRemove) {
        if (await removeFile(fileId)) {
          removedCount++;
        }
      }
      
      AppLogger.info('Removed $removedCount files for $entityType:$entityId', tag: 'FileLifecycle');
      return removedCount;
      
    } catch (e) {
      AppLogger.error('Failed to remove entity files: $e', tag: 'FileLifecycle');
      return 0;
    }
  }

  /// Executa limpeza baseada nas políticas
  Future<CleanupResult> performCleanup({bool force = false}) async {
    try {
      AppLogger.info('Starting cleanup (force: $force)', tag: 'FileLifecycle');
      
      final now = DateTime.now();
      final expiredFiles = <String>[];
      final unusedFiles = <String>[];
      final oversizedFiles = <String>[];
      
      // 1. Verificar arquivos expirados (time-based)
      for (final entry in _fileRegistry.entries) {
        final metadata = entry.value;
        
        if (metadata.policy == RetentionPolicy.permanent && !force) {
          continue;
        }
        
        // Time-based cleanup
        if (metadata.policy == RetentionPolicy.timeBased && 
            metadata.expiresAt != null && 
            now.isAfter(metadata.expiresAt!)) {
          expiredFiles.add(entry.key);
          continue;
        }
        
        // Usage-based cleanup
        if (metadata.policy == RetentionPolicy.usageBased) {
          final isRecent = now.difference(metadata.lastAccessedAt) < _config.recentUsagePeriod;
          final hasMinimumAccess = metadata.accessCount >= _config.minimumAccessCount;
          
          if (!isRecent && !hasMinimumAccess) {
            unusedFiles.add(entry.key);
          }
        }
      }
      
      // 2. Size-based cleanup (se necessário)
      if (_getTotalCacheSize() > _config.maxCacheSizeBytes) {
        // Ordenar por última vez acessado (mais antigo primeiro)
        final sortedFiles = _fileRegistry.entries.toList()
          ..sort((a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));
        
        int currentSize = _getTotalCacheSize();
        for (final entry in sortedFiles) {
          if (currentSize <= _config.maxCacheSizeBytes * 0.8) { // Limpar até 80% do limite
            break;
          }
          
          if (entry.value.policy != RetentionPolicy.permanent || force) {
            oversizedFiles.add(entry.key);
            currentSize -= entry.value.fileSize;
          }
        }
      }
      
      // 3. Remover arquivos identificados
      final allFilesToRemove = {...expiredFiles, ...unusedFiles, ...oversizedFiles};
      int removedCount = 0;
      int freedBytes = 0;
      
      for (final fileId in allFilesToRemove) {
        final metadata = _fileRegistry[fileId];
        if (metadata != null) {
          freedBytes += metadata.fileSize;
        }
        
        if (await removeFile(fileId)) {
          removedCount++;
        }
      }
      
      // Salvar timestamp da última limpeza
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCleanupKey, now.toIso8601String());
      
      final result = CleanupResult(
        removedCount: removedCount,
        freedBytes: freedBytes,
        expiredFiles: expiredFiles.length,
        unusedFiles: unusedFiles.length,
        oversizedFiles: oversizedFiles.length,
        timestamp: now,
      );
      
      AppLogger.info('Cleanup completed: $result', tag: 'FileLifecycle');
      return result;
      
    } catch (e) {
      AppLogger.error('Cleanup failed: $e', tag: 'FileLifecycle');
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

  /// Obtém estatísticas do cache
  CacheStatistics getStatistics() {
    final totalFiles = _fileRegistry.length;
    final totalSize = _getTotalCacheSize();
    
    final byEntity = <String, int>{};
    final byType = <String, int>{};
    final byPolicy = <RetentionPolicy, int>{};
    
    for (final metadata in _fileRegistry.values) {
      byEntity[metadata.entityId] = (byEntity[metadata.entityId] ?? 0) + 1;
      byType[metadata.entityType] = (byType[metadata.entityType] ?? 0) + 1;
      byPolicy[metadata.policy] = (byPolicy[metadata.policy] ?? 0) + 1;
    }
    
    return CacheStatistics(
      totalFiles: totalFiles,
      totalSizeBytes: totalSize,
      filesByEntity: byEntity,
      filesByType: byType,
      filesByPolicy: byPolicy,
      oldestFile: _getOldestFile(),
      newestFile: _getNewestFile(),
      mostAccessedFile: _getMostAccessedFile(),
    );
  }

  /// Busca arquivos por entidade
  List<FileLifecycleMetadata> getEntityFiles(String entityId, String entityType) {
    return _fileRegistry.values
        .where((metadata) => 
            metadata.entityId == entityId && 
            metadata.entityType == entityType)
        .toList();
  }

  /// Atualiza política de retenção de um arquivo
  Future<void> updateRetentionPolicy(
    String fileId, 
    RetentionPolicy newPolicy,
    {Duration? customRetention}
  ) async {
    final metadata = _fileRegistry[fileId];
    if (metadata == null) return;
    
    DateTime? newExpiresAt;
    if (newPolicy == RetentionPolicy.timeBased && customRetention != null) {
      newExpiresAt = DateTime.now().add(customRetention);
    }
    
    _fileRegistry[fileId] = metadata.copyWith(
      policy: newPolicy,
      expiresAt: newExpiresAt,
    );
    
    await _saveMetadata();
    AppLogger.info('Updated retention policy for $fileId to $newPolicy', tag: 'FileLifecycle');
  }

  // ========== Private Methods ==========

  String _generateFileId(String entityId, String entityType, String filePath) {
    final fileName = path.basename(filePath);
    return '${entityType}_${entityId}_$fileName'.replaceAll(RegExp(r'[^\w\-.]'), '_');
  }

  int _getTotalCacheSize() {
    return _fileRegistry.values.fold(0, (sum, metadata) => sum + metadata.fileSize);
  }

  FileLifecycleMetadata? _getOldestFile() {
    if (_fileRegistry.isEmpty) return null;
    
    return _fileRegistry.values.reduce((a, b) => 
        a.createdAt.isBefore(b.createdAt) ? a : b);
  }

  FileLifecycleMetadata? _getNewestFile() {
    if (_fileRegistry.isEmpty) return null;
    
    return _fileRegistry.values.reduce((a, b) => 
        a.createdAt.isAfter(b.createdAt) ? a : b);
  }

  FileLifecycleMetadata? _getMostAccessedFile() {
    if (_fileRegistry.isEmpty) return null;
    
    return _fileRegistry.values.reduce((a, b) => 
        a.accessCount > b.accessCount ? a : b);
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_config.cleanupInterval, (_) {
      performCleanup();
    });
  }

  Future<void> _loadMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_metadataKey);
      
      if (jsonString != null) {
        final jsonData = Map<String, dynamic>.from(
          jsonDecode(jsonString)
        );
        
        final List<dynamic> list = jsonData['files'] ?? [];
        
        for (final item in list) {
          final metadata = FileLifecycleMetadata.fromJson(
            Map<String, dynamic>.from(item)
          );
          _fileRegistry[metadata.fileId] = metadata;
        }
      }
      
      AppLogger.info('Loaded ${_fileRegistry.length} files from metadata', tag: 'FileLifecycle');
    } catch (e) {
      AppLogger.error('Failed to load metadata: $e', tag: 'FileLifecycle');
    }
  }

  Future<void> _saveMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _fileRegistry.values.map((m) => m.toJson()).toList();
      
      final jsonData = {
        'files': list,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_metadataKey, jsonEncode(jsonData));
      
    } catch (e) {
      AppLogger.error('Failed to save metadata: $e', tag: 'FileLifecycle');
    }
  }

  /// Dispose do gerenciador
  void dispose() {
    _cleanupTimer?.cancel();
  }
}

/// Resultado de uma operação de limpeza
class CleanupResult {
  final int removedCount;
  final int freedBytes;
  final int expiredFiles;
  final int unusedFiles;
  final int oversizedFiles;
  final DateTime timestamp;

  CleanupResult({
    required this.removedCount,
    required this.freedBytes,
    required this.expiredFiles,
    required this.unusedFiles,
    required this.oversizedFiles,
    required this.timestamp,
  });

  @override
  String toString() => 'CleanupResult(removed: $removedCount, freed: ${freedBytes ~/ 1024}KB, '
      'expired: $expiredFiles, unused: $unusedFiles, oversized: $oversizedFiles)';
}

/// Estatísticas do cache
class CacheStatistics {
  final int totalFiles;
  final int totalSizeBytes;
  final Map<String, int> filesByEntity;
  final Map<String, int> filesByType;
  final Map<RetentionPolicy, int> filesByPolicy;
  final FileLifecycleMetadata? oldestFile;
  final FileLifecycleMetadata? newestFile;
  final FileLifecycleMetadata? mostAccessedFile;

  CacheStatistics({
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.filesByEntity,
    required this.filesByType,
    required this.filesByPolicy,
    this.oldestFile,
    this.newestFile,
    this.mostAccessedFile,
  });

  String get formattedSize => '${totalSizeBytes ~/ (1024 * 1024)} MB';
}