import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/universal_storage_service.dart';
import '../logging/app_logger.dart';
import 'cache_service.dart';

class LogoCacheService {
  final UniversalStorageService _storage;
  final CacheService _cacheService;
  
  static const String _logoUrlKey = 'app_logo_url';
  static const String _logoFileKey = 'app_logo_file';
  static const String _logoMetadataKey = 'app_logo_metadata';

  LogoCacheService({
    required UniversalStorageService storage,
    required CacheService cacheService,
  }) : _storage = storage, _cacheService = cacheService;

  /// Salva URL da logo no cache
  Future<void> setLogoUrl(String url) async {
    try {
      await _storage.setString(_logoUrlKey, url);
      AppLogger.info('Logo URL cached: $url', tag: 'LogoCache');
    } catch (e) {
      AppLogger.error('Failed to cache logo URL: $e', tag: 'LogoCache');
    }
  }

  /// Recupera URL da logo do cache
  Future<String?> getLogoUrl() async {
    try {
      return await _storage.getString(_logoUrlKey);
    } catch (e) {
      AppLogger.error('Failed to get cached logo URL: $e', tag: 'LogoCache');
      return null;
    }
  }

  /// Salva arquivo de logo no cache
  Future<void> setLogoFile({
    required Uint8List bytes,
    required String originalFileName,
    String? url,
  }) async {
    try {
      // Gerar ID único para o arquivo
      final fileId = 'app_logo_${DateTime.now().millisecondsSinceEpoch}';
      
      // Cache do arquivo usando CacheService
      final cachedInfo = await _cacheService.cacheFile(
        fileId: fileId,
        bytes: bytes,
        originalPath: originalFileName,
        type: 'image',
      );
      
      // Salvar metadados no storage local
      final metadata = {
        'fileId': fileId,
        'localPath': cachedInfo.localPath,
        'originalFileName': originalFileName,
        'url': url,
        'cachedAt': DateTime.now().toIso8601String(),
        'fileSize': bytes.length,
      };
      
      await _storage.setString(_logoFileKey, fileId);
      await _storage.setString(_logoMetadataKey, json.encode(metadata));
      
      AppLogger.info('Logo file cached successfully: $fileId', tag: 'LogoCache');
    } catch (e) {
      AppLogger.error('Failed to cache logo file: $e', tag: 'LogoCache');
    }
  }

  /// Recupera arquivo de logo do cache
  Future<Uint8List?> getLogoFile() async {
    try {
      final fileId = await _storage.getString(_logoFileKey);
      if (fileId == null) {
        AppLogger.debug('No logo file cached', tag: 'LogoCache');
        return null;
      }

      final cachedBytes = await _cacheService.getCachedFile(fileId);
      if (cachedBytes != null) {
        AppLogger.debug('Logo file retrieved from cache: $fileId', tag: 'LogoCache');
        return cachedBytes;
      }

      AppLogger.warning('Logo file not found in cache: $fileId', tag: 'LogoCache');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get cached logo file: $e', tag: 'LogoCache');
      return null;
    }
  }

  /// Recupera metadados da logo
  Future<Map<String, dynamic>?> getLogoMetadata() async {
    try {
      final metadataJson = await _storage.getString(_logoMetadataKey);
      if (metadataJson == null) return null;

      return json.decode(metadataJson) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to get logo metadata: $e', tag: 'LogoCache');
      return null;
    }
  }

  /// Remove logo do cache
  Future<void> clearLogoCache() async {
    try {
      // Obter fileId antes de limpar
      final fileId = await _storage.getString(_logoFileKey);
      
      // Limpar storage local
      await _storage.remove(_logoUrlKey);
      await _storage.remove(_logoFileKey);
      await _storage.remove(_logoMetadataKey);
      
      // Remover arquivo do cache se existir
      if (fileId != null) {
        await _cacheService.removeCachedFile(fileId);
      }
      
      AppLogger.info('Logo cache cleared successfully', tag: 'LogoCache');
    } catch (e) {
      AppLogger.error('Failed to clear logo cache: $e', tag: 'LogoCache');
    }
  }

  /// Verifica se há logo em cache
  Future<bool> hasLogoInCache() async {
    try {
      final fileId = await _storage.getString(_logoFileKey);
      return fileId != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtém estatísticas do cache da logo
  Future<Map<String, dynamic>> getLogoCacheStats() async {
    try {
      final metadata = await getLogoMetadata();
      final hasFile = await hasLogoInCache();
      final url = await getLogoUrl();

      return {
        'hasLogo': hasFile,
        'logoUrl': url,
        'metadata': metadata,
        'cachedAt': metadata?['cachedAt'],
        'fileSize': metadata?['fileSize'],
        'originalFileName': metadata?['originalFileName'],
      };
    } catch (e) {
      AppLogger.error('Failed to get logo cache stats: $e', tag: 'LogoCache');
      return {
        'hasLogo': false,
        'error': e.toString(),
      };
    }
  }

  /// Atualiza logo com nova versão
  Future<void> updateLogoCache({
    required Uint8List bytes,
    required String originalFileName,
    String? url,
  }) async {
    try {
      // Limpar cache anterior
      await clearLogoCache();
      
      // Salvar nova logo
      await setLogoFile(
        bytes: bytes,
        originalFileName: originalFileName,
        url: url,
      );
      
      // Salvar URL se fornecida
      if (url != null) {
        await setLogoUrl(url);
      }
      
      AppLogger.info('Logo cache updated successfully', tag: 'LogoCache');
    } catch (e) {
      AppLogger.error('Failed to update logo cache: $e', tag: 'LogoCache');
      rethrow;
    }
  }
}

/// Provider para o serviço de cache de logo
final logoCacheServiceProvider = Provider<LogoCacheService>((ref) {
  final storage = ref.watch(universalStorageServiceProvider);
  final cacheService = CacheService(); // Instancia direta pois não tem provider
  
  return LogoCacheService(
    storage: storage,
    cacheService: cacheService,
  );
});