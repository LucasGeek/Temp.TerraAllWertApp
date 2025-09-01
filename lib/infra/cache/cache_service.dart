import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';
import 'models/cache_metadata.dart';

/// Serviço de gerenciamento de cache local para arquivos multimídia
class CacheService {
  static const String _cacheSubDir = 'terra_allwert_cache';
  static const String _metadataSubDir = 'metadata';
  static const String _imagesSubDir = 'images';
  static const String _videosSubDir = 'videos';
  static const String _documentsSubDir = 'documents';
  
  static const String _versionControlFile = 'version_control.json';
  static const String _cacheIndexFile = 'cache_index.json';

  late Directory _cacheDir;
  late Directory _metadataDir;
  late Directory _imagesDir;
  late Directory _videosDir;
  late Directory _documentsDir;
  
  Map<String, CachedFileInfo> _cacheIndex = {};
  CacheMetadata? _metadata;

  /// Inicializa o serviço de cache
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      _cacheDir = Directory(path.join(appDir.path, _cacheSubDir));
      
      // Criar estrutura de diretórios
      _metadataDir = Directory(path.join(_cacheDir.path, _metadataSubDir));
      _imagesDir = Directory(path.join(_cacheDir.path, _imagesSubDir));
      _videosDir = Directory(path.join(_cacheDir.path, _videosSubDir));
      _documentsDir = Directory(path.join(_cacheDir.path, _documentsSubDir));
      
      await _createDirectories();
      await _loadCacheIndex();
      await _loadMetadata();
      
      AppLogger.info('Cache service initialized at: ${_cacheDir.path}', tag: 'Cache');
    } catch (e) {
      AppLogger.error('Failed to initialize cache service: $e', tag: 'Cache');
      rethrow;
    }
  }

  /// Cria a estrutura de diretórios necessária
  Future<void> _createDirectories() async {
    await _cacheDir.create(recursive: true);
    await _metadataDir.create(recursive: true);
    await _imagesDir.create(recursive: true);
    await _videosDir.create(recursive: true);
    await _documentsDir.create(recursive: true);
  }

  /// Carrega o índice do cache
  Future<void> _loadCacheIndex() async {
    try {
      final indexFile = File(path.join(_metadataDir.path, _cacheIndexFile));
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        
        _cacheIndex = {};
        json.forEach((key, value) {
          _cacheIndex[key] = CachedFileInfo.fromJson(value as Map<String, dynamic>);
        });
        
        AppLogger.debug('Loaded ${_cacheIndex.length} entries from cache index', tag: 'Cache');
      }
    } catch (e) {
      AppLogger.error('Failed to load cache index: $e', tag: 'Cache');
      _cacheIndex = {};
    }
  }

  /// Salva o índice do cache
  Future<void> _saveCacheIndex() async {
    try {
      final indexFile = File(path.join(_metadataDir.path, _cacheIndexFile));
      final json = <String, dynamic>{};
      
      _cacheIndex.forEach((key, value) {
        json[key] = value.toJson();
      });
      
      await indexFile.writeAsString(jsonEncode(json));
      AppLogger.debug('Saved cache index with ${_cacheIndex.length} entries', tag: 'Cache');
    } catch (e) {
      AppLogger.error('Failed to save cache index: $e', tag: 'Cache');
    }
  }

  /// Carrega metadados do cache
  Future<void> _loadMetadata() async {
    try {
      final metadataFile = File(path.join(_metadataDir.path, _versionControlFile));
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _metadata = CacheMetadata.fromJson(json);
      } else {
        _metadata = CacheMetadata(
          version: '1.0.0',
          lastSync: DateTime.now(),
          itemTimestamps: {},
          totalFiles: 0,
          totalSize: 0,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to load cache metadata: $e', tag: 'Cache');
      _metadata = CacheMetadata(
        version: '1.0.0',
        lastSync: DateTime.now(),
        itemTimestamps: {},
        totalFiles: 0,
        totalSize: 0,
      );
    }
  }

  /// Salva metadados do cache
  Future<void> _saveMetadata() async {
    if (_metadata == null) return;
    
    try {
      final metadataFile = File(path.join(_metadataDir.path, _versionControlFile));
      await metadataFile.writeAsString(jsonEncode(_metadata!.toJson()));
      AppLogger.debug('Saved cache metadata', tag: 'Cache');
    } catch (e) {
      AppLogger.error('Failed to save cache metadata: $e', tag: 'Cache');
    }
  }

  /// Calcula checksum de um arquivo
  String _calculateChecksum(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Obtém diretório baseado no tipo de arquivo
  Directory _getDirectoryForType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return _imagesDir;
      case 'video':
        return _videosDir;
      case 'document':
        return _documentsDir;
      default:
        return _documentsDir;
    }
  }

  /// Salva arquivo no cache local
  Future<CachedFileInfo> cacheFile({
    required String fileId,
    required Uint8List bytes,
    required String originalPath,
    required String type,
  }) async {
    try {
      final extension = path.extension(originalPath);
      final fileName = '$fileId$extension';
      final targetDir = _getDirectoryForType(type);
      final targetFile = File(path.join(targetDir.path, fileName));
      
      // Salvar arquivo
      await targetFile.writeAsBytes(bytes);
      
      // Calcular checksum
      final checksum = _calculateChecksum(bytes);
      
      // Criar informações do arquivo
      final fileInfo = CachedFileInfo(
        id: fileId,
        originalPath: originalPath,
        localPath: targetFile.path,
        type: type,
        cachedAt: DateTime.now(),
        lastModified: DateTime.now(),
        size: bytes.length,
        checksum: checksum,
      );
      
      // Atualizar índice
      _cacheIndex[fileId] = fileInfo;
      await _saveCacheIndex();
      
      // Atualizar metadados
      _metadata = _metadata!.copyWith(
        totalFiles: _cacheIndex.length,
        totalSize: _cacheIndex.values.fold(0, (sum, info) => sum + info.size),
      );
      await _saveMetadata();
      
      AppLogger.info('Cached file: $fileId (${bytes.length} bytes)', tag: 'Cache');
      return fileInfo;
      
    } catch (e) {
      AppLogger.error('Failed to cache file $fileId: $e', tag: 'Cache');
      rethrow;
    }
  }

  /// Obtém arquivo do cache
  Future<Uint8List?> getCachedFile(String fileId) async {
    try {
      final fileInfo = _cacheIndex[fileId];
      if (fileInfo == null) {
        AppLogger.debug('File not found in cache: $fileId', tag: 'Cache');
        return null;
      }
      
      final file = File(fileInfo.localPath);
      if (!await file.exists()) {
        AppLogger.warning('Cache file missing on disk: $fileId', tag: 'Cache');
        // Remove from index
        _cacheIndex.remove(fileId);
        await _saveCacheIndex();
        return null;
      }
      
      final bytes = await file.readAsBytes();
      
      // Verificar integridade
      final checksum = _calculateChecksum(bytes);
      if (checksum != fileInfo.checksum) {
        AppLogger.error('Cache file corrupted: $fileId', tag: 'Cache');
        return null;
      }
      
      AppLogger.debug('Retrieved cached file: $fileId (${bytes.length} bytes)', tag: 'Cache');
      return bytes;
      
    } catch (e) {
      AppLogger.error('Failed to get cached file $fileId: $e', tag: 'Cache');
      return null;
    }
  }

  /// Obtém informações de um arquivo em cache
  CachedFileInfo? getCachedFileInfo(String fileId) {
    return _cacheIndex[fileId];
  }

  /// Lista todos os arquivos em cache
  List<CachedFileInfo> getAllCachedFiles() {
    return _cacheIndex.values.toList();
  }

  /// Remove arquivo do cache
  Future<bool> removeCachedFile(String fileId) async {
    try {
      final fileInfo = _cacheIndex[fileId];
      if (fileInfo == null) return true;
      
      final file = File(fileInfo.localPath);
      if (await file.exists()) {
        await file.delete();
      }
      
      _cacheIndex.remove(fileId);
      await _saveCacheIndex();
      
      // Atualizar metadados
      _metadata = _metadata!.copyWith(
        totalFiles: _cacheIndex.length,
        totalSize: _cacheIndex.values.fold(0, (sum, info) => sum + info.size),
      );
      await _saveMetadata();
      
      AppLogger.info('Removed cached file: $fileId', tag: 'Cache');
      return true;
      
    } catch (e) {
      AppLogger.error('Failed to remove cached file $fileId: $e', tag: 'Cache');
      return false;
    }
  }

  /// Limpa todo o cache
  Future<void> clearCache() async {
    try {
      await _cacheDir.delete(recursive: true);
      await _createDirectories();
      
      _cacheIndex.clear();
      _metadata = CacheMetadata(
        version: '1.0.0',
        lastSync: DateTime.now(),
        itemTimestamps: {},
        totalFiles: 0,
        totalSize: 0,
      );
      
      await _saveCacheIndex();
      await _saveMetadata();
      
      AppLogger.info('Cache cleared completely', tag: 'Cache');
    } catch (e) {
      AppLogger.error('Failed to clear cache: $e', tag: 'Cache');
    }
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() {
    return {
      'totalFiles': _cacheIndex.length,
      'totalSize': _cacheIndex.values.fold(0, (sum, info) => sum + info.size),
      'imageFiles': _cacheIndex.values.where((info) => info.type == 'image').length,
      'videoFiles': _cacheIndex.values.where((info) => info.type == 'video').length,
      'documentFiles': _cacheIndex.values.where((info) => info.type == 'document').length,
      'lastSync': _metadata?.lastSync.toIso8601String(),
      'version': _metadata?.version,
    };
  }

  /// Marca arquivo como enviado para MinIO
  Future<void> markAsUploaded(String fileId, String minioPath) async {
    final fileInfo = _cacheIndex[fileId];
    if (fileInfo == null) return;
    
    _cacheIndex[fileId] = fileInfo.copyWith(
      minioPath: minioPath,
      uploadedAt: DateTime.now(),
      isUploaded: true,
    );
    
    await _saveCacheIndex();
    AppLogger.debug('Marked file as uploaded: $fileId -> $minioPath', tag: 'Cache');
  }

  /// Verifica se arquivo precisa ser sincronizado
  bool needsSync(String fileId) {
    final fileInfo = _cacheIndex[fileId];
    if (fileInfo == null) return false;
    return fileInfo.isUploaded != true;
  }

  /// Obtém arquivos que precisam de sincronização
  List<CachedFileInfo> getFilesNeedingSync() {
    return _cacheIndex.values
        .where((info) => info.isUploaded != true)
        .toList();
  }

  /// Atualiza timestamp de sincronização
  Future<void> updateSyncTimestamp(String itemId) async {
    if (_metadata == null) return;
    
    final updatedTimestamps = Map<String, DateTime>.from(_metadata!.itemTimestamps);
    updatedTimestamps[itemId] = DateTime.now();
    
    _metadata = _metadata!.copyWith(
      lastSync: DateTime.now(),
      itemTimestamps: updatedTimestamps,
    );
    
    await _saveMetadata();
  }
}