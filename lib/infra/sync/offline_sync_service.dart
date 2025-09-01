import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

import '../cache/cache_service.dart';
import '../graphql/graphql_client.dart';
import '../graphql/mutations/file_upload_mutations.dart';
import '../logging/app_logger.dart';
import '../platform/platform_service.dart';

/// Serviço de sincronização offline que gerencia URLs da API e fallback ZIP
class OfflineSyncService {
  final GraphQLClientService _graphqlClient;
  final CacheService _cacheService;
  final Dio _dio = Dio();

  // Cache de URLs da API para evitar chamadas desnecessárias
  final Map<String, _UrlCacheEntry> _urlCache = {};
  static const Duration _urlCacheExpiry = Duration(hours: 1);

  OfflineSyncService({
    required GraphQLClientService graphqlClient,
    required CacheService cacheService,
  }) : _graphqlClient = graphqlClient,
       _cacheService = cacheService;

  /// Obtém URL de um arquivo baseado na plataforma e conectividade
  Future<String?> getFileUrl({
    required String fileId,
    required String routeId,
    String? originalFileName,
  }) async {
    try {
      // Web: SEMPRE usar URLs da API
      if (kIsWeb) {
        return await _getApiUrl(fileId: fileId, routeId: routeId);
      }

      // Mobile/Desktop: Tentar API primeiro, fallback para ZIP offline
      if (await _hasInternetConnection()) {
        final apiUrl = await _getApiUrl(fileId: fileId, routeId: routeId);
        if (apiUrl != null) {
          return apiUrl;
        }
      }

      // Fallback: Buscar no ZIP offline (mobile/desktop sem internet)
      return await _getOfflineZipUrl(
        fileId: fileId, 
        routeId: routeId, 
        originalFileName: originalFileName,
      );

    } catch (e) {
      AppLogger.error('Failed to get file URL for $fileId: $e', tag: 'OfflineSync');
      return null;
    }
  }

  /// Obtém URLs de múltiplos arquivos (otimizado para batch)
  Future<Map<String, String?>> getFileUrls({
    required List<String> fileIds,
    required String routeId,
  }) async {
    try {
      final result = <String, String?>{};

      // Web: SEMPRE usar URLs da API
      if (kIsWeb) {
        return await _getBatchApiUrls(fileIds: fileIds, routeId: routeId);
      }

      // Mobile/Desktop: Tentar API primeiro
      if (await _hasInternetConnection()) {
        final apiUrls = await _getBatchApiUrls(fileIds: fileIds, routeId: routeId);
        
        // Se conseguiu todas as URLs da API, retornar
        if (apiUrls.values.every((url) => url != null)) {
          return apiUrls;
        }
        
        // Completar com ZIP offline para URLs que falharam
        for (final fileId in fileIds) {
          if (apiUrls[fileId] == null) {
            result[fileId] = await _getOfflineZipUrl(fileId: fileId, routeId: routeId);
          } else {
            result[fileId] = apiUrls[fileId];
          }
        }
      } else {
        // Sem internet: usar apenas ZIP offline
        for (final fileId in fileIds) {
          result[fileId] = await _getOfflineZipUrl(fileId: fileId, routeId: routeId);
        }
      }

      return result;
    } catch (e) {
      AppLogger.error('Failed to get batch file URLs: $e', tag: 'OfflineSync');
      return {};
    }
  }

  /// Obtém URL da API GraphQL (com cache)
  Future<String?> _getApiUrl({
    required String fileId,
    required String routeId,
  }) async {
    try {
      // Verificar cache primeiro
      final cacheKey = '${routeId}_$fileId';
      final cachedEntry = _urlCache[cacheKey];
      
      if (cachedEntry != null && !cachedEntry.isExpired) {
        AppLogger.debug('Using cached API URL for $fileId', tag: 'OfflineSync');
        return cachedEntry.url;
      }

      // TODO: Implementar chamada GraphQL real quando API estiver pronta
      AppLogger.debug('TODO: Getting API URL for file: $fileId', tag: 'OfflineSync');
      
      /*
      // Código real para quando API estiver implementada:
      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(getSignedDownloadUrlsQuery),
          variables: {
            'input': {
              'routeId': routeId,
              'fileIds': [fileId],
              'expirationMinutes': 60,
            }
          },
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL error getting download URL: ${result.exception}', tag: 'OfflineSync');
        return null;
      }

      final data = result.data?['getSignedDownloadUrls'];
      if (data != null && data['urls'] != null && data['urls'].isNotEmpty) {
        final url = data['urls'][0]['downloadUrl'] as String?;
        
        if (url != null) {
          // Cache da URL por 1 hora
          _urlCache[cacheKey] = _UrlCacheEntry(url, DateTime.now().add(_urlCacheExpiry));
          return url;
        }
      }
      */

      // Mock para desenvolvimento
      final mockUrl = 'https://api.example.com/files/$routeId/$fileId/download';
      _urlCache[cacheKey] = _UrlCacheEntry(mockUrl, DateTime.now().add(_urlCacheExpiry));
      return mockUrl;

    } catch (e) {
      AppLogger.error('Failed to get API URL for $fileId: $e', tag: 'OfflineSync');
      return null;
    }
  }

  /// Obtém URLs de múltiplos arquivos da API (otimizado)
  Future<Map<String, String?>> _getBatchApiUrls({
    required List<String> fileIds,
    required String routeId,
  }) async {
    try {
      final result = <String, String?>{};

      // TODO: Implementar batch query GraphQL real quando API estiver pronta
      AppLogger.debug('TODO: Getting batch API URLs for ${fileIds.length} files', tag: 'OfflineSync');
      
      /*
      // Código real para quando API estiver implementada:
      final result = await _graphqlClient.query(
        QueryOptions(
          document: gql(getSignedDownloadUrlsQuery),
          variables: {
            'input': {
              'routeId': routeId,
              'fileIds': fileIds,
              'expirationMinutes': 60,
            }
          },
        ),
      );

      if (!result.hasException && result.data?['getSignedDownloadUrls'] != null) {
        final urls = result.data!['getSignedDownloadUrls']['urls'] as List?;
        
        if (urls != null) {
          for (final urlData in urls) {
            final fileId = urlData['fileId'] as String?;
            final downloadUrl = urlData['downloadUrl'] as String?;
            
            if (fileId != null && downloadUrl != null) {
              result[fileId] = downloadUrl;
              // Cache da URL
              final cacheKey = '${routeId}_$fileId';
              _urlCache[cacheKey] = _UrlCacheEntry(downloadUrl, DateTime.now().add(_urlCacheExpiry));
            }
          }
        }
      }
      */

      // Mock para desenvolvimento
      for (final fileId in fileIds) {
        final mockUrl = 'https://api.example.com/files/$routeId/$fileId/download';
        result[fileId] = mockUrl;
        
        final cacheKey = '${routeId}_$fileId';
        _urlCache[cacheKey] = _UrlCacheEntry(mockUrl, DateTime.now().add(_urlCacheExpiry));
      }

      return result;
    } catch (e) {
      AppLogger.error('Failed to get batch API URLs: $e', tag: 'OfflineSync');
      return {};
    }
  }

  /// Obtém URL do arquivo no ZIP offline (apenas mobile/desktop)
  Future<String?> _getOfflineZipUrl({
    required String fileId,
    required String routeId,
    String? originalFileName,
  }) async {
    if (kIsWeb) {
      AppLogger.warning('Offline ZIP not supported on web platform', tag: 'OfflineSync');
      return null;
    }

    try {
      // Verificar se existe arquivo extraído do ZIP
      final extractedPath = await _getExtractedFilePath(
        fileId: fileId,
        routeId: routeId,
        originalFileName: originalFileName,
      );

      if (extractedPath != null && await File(extractedPath).exists()) {
        AppLogger.debug('Found offline file: $extractedPath', tag: 'OfflineSync');
        return 'file://$extractedPath';
      }

      AppLogger.debug('No offline file found for $fileId', tag: 'OfflineSync');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get offline ZIP URL for $fileId: $e', tag: 'OfflineSync');
      return null;
    }
  }

  /// Baixa e extrai ZIP completo para uso offline
  Future<bool> downloadAndExtractZip({
    required String routeId,
    Function(double progress)? onProgress,
  }) async {
    if (kIsWeb) {
      AppLogger.warning('ZIP download not supported on web platform', tag: 'OfflineSync');
      return false;
    }

    try {
      AppLogger.info('Starting ZIP download for route: $routeId', tag: 'OfflineSync');

      // TODO: Implementar download ZIP real quando API estiver pronta
      /*
      // Código real para quando API estiver implementada:
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(requestFullSyncMutation),
          variables: {
            'input': {
              'routeId': routeId,
              'includeTypes': ['image', 'video', 'document'],
              'compressionLevel': 6,
            }
          },
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL error requesting ZIP: ${result.exception}', tag: 'OfflineSync');
        return false;
      }

      final zipUrl = result.data?['requestFullSync']?['zipUrl'] as String?;
      if (zipUrl == null) {
        AppLogger.error('No ZIP URL returned from API', tag: 'OfflineSync');
        return false;
      }

      // Download do ZIP
      final zipPath = await _downloadZipFile(zipUrl, routeId, onProgress);
      if (zipPath == null) {
        return false;
      }

      // Extrair ZIP
      return await _extractZipFile(zipPath, routeId);
      */

      // Mock para desenvolvimento - simular download e extração
      AppLogger.debug('TODO: Mock ZIP download simulation', tag: 'OfflineSync');
      
      // Simular progresso
      if (onProgress != null) {
        for (int i = 0; i <= 100; i += 10) {
          await Future.delayed(Duration(milliseconds: 100));
          onProgress(i / 100.0);
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Failed to download and extract ZIP: $e', tag: 'OfflineSync');
      return false;
    }
  }

  /// Download do arquivo ZIP
  Future<String?> _downloadZipFile(
    String zipUrl, 
    String routeId, 
    Function(double progress)? onProgress,
  ) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final zipDir = Directory(path.join(appDir.path, 'offline_zips'));
      await zipDir.create(recursive: true);

      final zipPath = path.join(zipDir.path, '${routeId}_sync.zip');

      await _dio.download(
        zipUrl,
        zipPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      AppLogger.info('ZIP downloaded successfully: $zipPath', tag: 'OfflineSync');
      return zipPath;
    } catch (e) {
      AppLogger.error('Failed to download ZIP: $e', tag: 'OfflineSync');
      return null;
    }
  }

  /// Extrai arquivo ZIP para estrutura offline
  Future<bool> _extractZipFile(String zipPath, String routeId) async {
    try {
      final zipFile = File(zipPath);
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      final appDir = await getApplicationSupportDirectory();
      final extractDir = Directory(path.join(appDir.path, 'offline_files', routeId));
      await extractDir.create(recursive: true);

      for (final file in archive) {
        if (file.isFile) {
          final fileName = file.name;
          final filePath = path.join(extractDir.path, fileName);
          
          // Criar diretório pai se necessário
          final parentDir = Directory(path.dirname(filePath));
          await parentDir.create(recursive: true);
          
          final outputFile = File(filePath);
          await outputFile.writeAsBytes(file.content as List<int>);
          
          AppLogger.debug('Extracted file: $fileName', tag: 'OfflineSync');
        }
      }

      // Remover arquivo ZIP após extração
      await zipFile.delete();
      
      AppLogger.info('ZIP extracted successfully for route: $routeId', tag: 'OfflineSync');
      return true;
    } catch (e) {
      AppLogger.error('Failed to extract ZIP: $e', tag: 'OfflineSync');
      return false;
    }
  }

  /// Obtém caminho do arquivo extraído
  Future<String?> _getExtractedFilePath({
    required String fileId,
    required String routeId,
    String? originalFileName,
  }) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final extractDir = Directory(path.join(appDir.path, 'offline_files', routeId));

      if (!await extractDir.exists()) {
        return null;
      }

      // Tentar diferentes possibilidades de nome de arquivo
      final possibleNames = [
        fileId,
        originalFileName,
        '$fileId.jpg',
        '$fileId.png',
        '$fileId.mp4',
        '$fileId.pdf',
      ].where((name) => name != null).cast<String>();

      for (final fileName in possibleNames) {
        final filePath = path.join(extractDir.path, fileName);
        if (await File(filePath).exists()) {
          return filePath;
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to get extracted file path: $e', tag: 'OfflineSync');
      return null;
    }
  }

  /// Verifica conectividade com internet
  Future<bool> _hasInternetConnection() async {
    return await _graphqlClient.hasNetworkConnection();
  }

  /// Limpa cache de URLs expiradas
  void _cleanExpiredUrlCache() {
    final now = DateTime.now();
    _urlCache.removeWhere((key, entry) => entry.isExpired);
  }

  /// Obtém estatísticas do sync offline
  Map<String, dynamic> getSyncStats() {
    return {
      'cachedUrls': _urlCache.length,
      'platform': kIsWeb ? 'web' : 'mobile',
      'supportsOffline': !kIsWeb,
    };
  }

  /// Limpa todos os dados offline
  Future<void> clearOfflineData() async {
    if (kIsWeb) return;

    try {
      final appDir = await getApplicationSupportDirectory();
      
      // Remover arquivos extraídos
      final offlineDir = Directory(path.join(appDir.path, 'offline_files'));
      if (await offlineDir.exists()) {
        await offlineDir.delete(recursive: true);
      }
      
      // Remover ZIPs
      final zipDir = Directory(path.join(appDir.path, 'offline_zips'));
      if (await zipDir.exists()) {
        await zipDir.delete(recursive: true);
      }
      
      // Limpar cache de URLs
      _urlCache.clear();
      
      AppLogger.info('Offline data cleared', tag: 'OfflineSync');
    } catch (e) {
      AppLogger.error('Failed to clear offline data: $e', tag: 'OfflineSync');
    }
  }

  void dispose() {
    _urlCache.clear();
  }
}

/// Entry de cache para URLs da API
class _UrlCacheEntry {
  final String url;
  final DateTime expiresAt;

  _UrlCacheEntry(this.url, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}