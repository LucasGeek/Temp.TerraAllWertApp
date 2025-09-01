import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../graphql/graphql_client.dart';
import '../logging/app_logger.dart';
import '../download/background_downloader.dart';
import 'zip_manager.dart';

/// Serviço de sincronização offline que gerencia URLs da API e fallback ZIP
class OfflineSyncService {
  final GraphQLClientService _graphqlClient;
  final BackgroundDownloader _downloader = BackgroundDownloader();
  final ZipManager _zipManager = ZipManager();

  // Cache de URLs da API para evitar chamadas desnecessárias
  final Map<String, _UrlCacheEntry> _urlCache = {};
  static const Duration _urlCacheExpiry = Duration(hours: 1);

  OfflineSyncService({
    required GraphQLClientService graphqlClient,
  }) : _graphqlClient = graphqlClient;

  /// Obtém URL de um arquivo baseado na plataforma e conectividade
  /// Com download automático em background se necessário (offline-first)
  Future<String?> getFileUrl({
    required String fileId,
    required String routeId,
    String? originalFileName,
    Function(DownloadProgress)? onDownloadProgress,
  }) async {
    try {
      // Web: SEMPRE usar URLs da API (sem download)
      if (kIsWeb) {
        return await _getApiUrl(fileId: fileId, routeId: routeId);
      }

      // Mobile/Desktop: Implementar estratégia offline-first

      // 1. Verificar se arquivo já existe offline
      final offlineUrl = await _getOfflineZipUrl(
        fileId: fileId, 
        routeId: routeId, 
        originalFileName: originalFileName,
      );
      
      if (offlineUrl != null) {
        AppLogger.debug('File found offline: $fileId', tag: 'OfflineSync');
        return offlineUrl;
      }

      // 2. Se não existe offline e tem internet, baixar em background
      if (await _hasInternetConnection()) {
        final apiUrl = await _getApiUrl(fileId: fileId, routeId: routeId);
        if (apiUrl != null) {
          // Iniciar download em background para uso futuro (offline-first)
          _downloadFileInBackground(
            fileId: fileId,
            routeId: routeId,
            apiUrl: apiUrl,
            originalFileName: originalFileName ?? '$fileId.dat',
            onProgress: onDownloadProgress,
          );
          
          // Retornar URL da API para uso imediato
          return apiUrl;
        }
      }

      // 3. Sem conexão e sem arquivo offline
      AppLogger.warning('File not available offline and no internet connection: $fileId', tag: 'OfflineSync');
      return null;

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

  /// Obtém URL do arquivo offline (ZIP extraído ou download background)
  Future<String?> _getOfflineZipUrl({
    required String fileId,
    required String routeId,
    String? originalFileName,
  }) async {
    if (kIsWeb) {
      AppLogger.warning('Offline files not supported on web platform', tag: 'OfflineSync');
      return null;
    }

    try {
      // 1. Verificar se existe arquivo baixado pelo BackgroundDownloader
      final downloadedPath = await _getDownloadedFilePath(
        fileId: fileId,
        routeId: routeId,
        originalFileName: originalFileName,
      );

      if (downloadedPath != null && await File(downloadedPath).exists()) {
        AppLogger.debug('Found downloaded offline file: $downloadedPath', tag: 'OfflineSync');
        return 'file://$downloadedPath';
      }

      // 2. Fallback: Verificar se existe arquivo extraído do ZIP (compatibilidade)
      final extractedPath = await _getExtractedFilePath(
        fileId: fileId,
        routeId: routeId,
        originalFileName: originalFileName,
      );

      if (extractedPath != null && await File(extractedPath).exists()) {
        AppLogger.debug('Found offline extracted file: $extractedPath', tag: 'OfflineSync');
        return 'file://$extractedPath';
      }

      AppLogger.debug('No offline file found for $fileId', tag: 'OfflineSync');
      return null;
    } catch (e) {
      AppLogger.error('Failed to get offline file URL for $fileId: $e', tag: 'OfflineSync');
      return null;
    }
  }

  /// Obtém caminho do arquivo baixado pelo BackgroundDownloader
  Future<String?> _getDownloadedFilePath({
    required String fileId,
    required String routeId,
    String? originalFileName,
  }) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final downloadDir = Directory(path.join(appDir.path, 'downloads', routeId));

      if (!await downloadDir.exists()) {
        return null;
      }

      // Tentar diferentes possibilidades de nome de arquivo
      final possibleNames = [
        originalFileName,
        fileId,
        '$fileId.jpg',
        '$fileId.png',
        '$fileId.mp4',
        '$fileId.pdf',
        '$fileId.dat', // nome padrão do BackgroundDownloader
      ].where((name) => name != null).cast<String>();

      for (final fileName in possibleNames) {
        final filePath = path.join(downloadDir.path, fileName);
        if (await File(filePath).exists()) {
          return filePath;
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to get downloaded file path: $e', tag: 'OfflineSync');
      return null;
    }
  }

  /// Baixa e extrai ZIP completo para uso offline com versionamento
  Future<ZipDownloadResult> downloadAndExtractZip({
    required String routeId,
    String? zipUrl,
    String? version,
    Function(double progress)? onProgress,
    Function(ZipProgress zipProgress)? onZipProgress,
    bool cleanupOldVersions = true,
  }) async {
    if (kIsWeb) {
      AppLogger.warning('ZIP download not supported on web platform', tag: 'OfflineSync');
      return const ZipDownloadResult(
        success: false,
        error: 'ZIP operations not supported on web platform',
      );
    }

    try {
      AppLogger.info('Starting ZIP download for route: $routeId', tag: 'OfflineSync');

      // Se não foi fornecido URL do ZIP, tentar obter da API
      String? effectiveZipUrl = zipUrl;
      String effectiveVersion = version ?? DateTime.now().millisecondsSinceEpoch.toString();

      if (effectiveZipUrl == null) {
        // TODO: Implementar busca de URL do ZIP via GraphQL quando API estiver pronta
        /*
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
          return ZipDownloadResult(
            success: false,
            error: 'GraphQL error: ${result.exception}',
          );
        }

        effectiveZipUrl = result.data?['requestFullSync']?['zipUrl'] as String?;
        effectiveVersion = result.data?['requestFullSync']?['version'] as String? ?? effectiveVersion;
        */

        // Mock para desenvolvimento
        AppLogger.debug('TODO: Using mock ZIP URL for development', tag: 'OfflineSync');
        effectiveZipUrl = 'https://api.example.com/routes/$routeId/download.zip';
      }

      // effectiveZipUrl sempre terá valor aqui (mock ou API)
      // Verificação removida pois sempre será não-null

      // Usar ZipManager para download, extração e versionamento
      final result = await _zipManager.downloadAndExtractZip(
        zipUrl: effectiveZipUrl,
        routeId: routeId,
        version: effectiveVersion,
        onProgress: onZipProgress ?? (zipProgress) {
          // Converter ZipProgress para callback de double se necessário
          if (onProgress != null) {
            onProgress(zipProgress.progress);
          }
        },
        cleanupOldVersions: cleanupOldVersions,
      );

      if (result.success) {
        AppLogger.info(
          'ZIP download and extraction completed: $routeId v$effectiveVersion (${result.extractedFiles} files)',
          tag: 'OfflineSync',
        );
      } else {
        AppLogger.error('ZIP download failed: ${result.error}', tag: 'OfflineSync');
      }

      return result;

    } catch (e) {
      AppLogger.error('Failed to download and extract ZIP: $e', tag: 'OfflineSync');
      return ZipDownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Versão simplificada para compatibilidade (retorna apenas bool)
  Future<bool> downloadAndExtractZipSimple({
    required String routeId,
    String? zipUrl,
    String? version,
    Function(double progress)? onProgress,
  }) async {
    final result = await downloadAndExtractZip(
      routeId: routeId,
      zipUrl: zipUrl,
      version: version,
      onProgress: onProgress,
    );
    return result.success;
  }


  /// Obtém caminho do arquivo extraído (com suporte a versionamento)
  Future<String?> _getExtractedFilePath({
    required String fileId,
    required String routeId,
    String? originalFileName,
  }) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      
      // 1. Tentar buscar na versão atual (versionada pelo ZipManager)
      final currentVersion = _zipManager.getCurrentVersion(routeId);
      if (currentVersion != null) {
        final versionedPath = await _findFileInDirectory(
          Directory(currentVersion.extractedPath),
          fileId,
          originalFileName,
        );
        if (versionedPath != null) {
          return versionedPath;
        }
      }

      // 2. Fallback: Buscar em todas as versões disponíveis
      final versions = await _zipManager.getAvailableVersions(routeId);
      for (final version in versions) {
        final versionedPath = await _findFileInDirectory(
          Directory(version.extractedPath),
          fileId,
          originalFileName,
        );
        if (versionedPath != null) {
          return versionedPath;
        }
      }

      // 3. Fallback: Buscar no diretório legacy (compatibilidade)
      final legacyDir = Directory(path.join(appDir.path, 'offline_files', routeId));
      if (await legacyDir.exists()) {
        return await _findFileInDirectory(legacyDir, fileId, originalFileName);
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to get extracted file path: $e', tag: 'OfflineSync');
      return null;
    }
  }

  /// Busca arquivo em um diretório específico
  Future<String?> _findFileInDirectory(
    Directory directory,
    String fileId,
    String? originalFileName,
  ) async {
    if (!await directory.exists()) {
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
      '$fileId.doc',
      '$fileId.docx',
      '$fileId.webp',
    ].where((name) => name != null).cast<String>();

    for (final fileName in possibleNames) {
      final filePath = path.join(directory.path, fileName);
      if (await File(filePath).exists()) {
        return filePath;
      }
    }

    return null;
  }

  /// Verifica conectividade com internet
  Future<bool> _hasInternetConnection() async {
    return await _graphqlClient.hasNetworkConnection();
  }

  /// Baixa arquivo em background para uso offline futuro
  Future<void> _downloadFileInBackground({
    required String fileId,
    required String routeId,
    required String apiUrl,
    required String originalFileName,
    Function(DownloadProgress)? onProgress,
  }) async {
    try {
      AppLogger.info('Starting background download for offline cache: $fileId', tag: 'OfflineSync');
      
      final config = DownloadConfig(
        url: apiUrl,
        fileName: originalFileName,
        routeId: routeId,
        fileId: fileId,
        timeout: const Duration(minutes: 10),
      );

      // Iniciar download assíncrono em background
      _downloader.downloadFile(
        config: config,
        onProgress: (progress) {
          AppLogger.debug(
            'Downloading $fileId: ${(progress.progress * 100).toInt()}%',
            tag: 'OfflineSync',
          );
          onProgress?.call(progress);
        },
      ).then((result) {
        if (result.success) {
          AppLogger.info(
            'Background download completed: $fileId -> ${result.filePath}',
            tag: 'OfflineSync',
          );
        } else {
          AppLogger.error(
            'Background download failed: $fileId -> ${result.error}',
            tag: 'OfflineSync',
          );
        }
      }).catchError((error) {
        AppLogger.error('Background download error: $fileId -> $error', tag: 'OfflineSync');
      });

    } catch (e) {
      AppLogger.error('Failed to start background download: $fileId -> $e', tag: 'OfflineSync');
    }
  }

  /// Força download de arquivo específico com progresso
  Future<DownloadResult> downloadFileForOffline({
    required String fileId,
    required String routeId,
    String? originalFileName,
    Function(DownloadProgress)? onProgress,
  }) async {
    if (kIsWeb) {
      AppLogger.warning('Offline download not supported on web', tag: 'OfflineSync');
      return const DownloadResult(
        success: false,
        error: 'Offline downloads not supported on web platform',
      );
    }

    try {
      // Obter URL da API
      final apiUrl = await _getApiUrl(fileId: fileId, routeId: routeId);
      if (apiUrl == null) {
        return const DownloadResult(
          success: false,
          error: 'Could not obtain API URL for download',
        );
      }

      final config = DownloadConfig(
        url: apiUrl,
        fileName: originalFileName ?? '$fileId.dat',
        routeId: routeId,
        fileId: fileId,
        timeout: const Duration(minutes: 15),
      );

      AppLogger.info('Starting forced download for offline: $fileId', tag: 'OfflineSync');

      final result = await _downloader.downloadFile(
        config: config,
        onProgress: onProgress,
      );

      if (result.success) {
        AppLogger.info('Forced download completed: $fileId', tag: 'OfflineSync');
      }

      return result;

    } catch (e) {
      AppLogger.error('Forced download failed: $fileId -> $e', tag: 'OfflineSync');
      return DownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Obtém stream de progresso de download
  Stream<DownloadProgress>? getDownloadProgressStream(String fileId) {
    return _downloader.getProgressStream(fileId);
  }

  /// Cancela download em progresso
  Future<bool> cancelDownload(String fileId) async {
    return await _downloader.cancelDownload(fileId);
  }

  /// Verifica se arquivo está sendo baixado
  bool isDownloading(String fileId) {
    return _downloader.isDownloading(fileId);
  }


  /// Obtém stream de progresso do ZIP
  Stream<ZipProgress>? getZipProgressStream(String routeId) {
    return _zipManager.getProgressStream(routeId);
  }

  /// Obtém versão atual do ZIP para uma rota
  ZipVersion? getCurrentZipVersion(String routeId) {
    return _zipManager.getCurrentVersion(routeId);
  }

  /// Lista todas as versões ZIP disponíveis para uma rota
  Future<List<ZipVersion>> getAvailableZipVersions(String routeId) async {
    return await _zipManager.getAvailableVersions(routeId);
  }

  /// Remove completamente todos os dados ZIP de uma rota
  Future<bool> removeRouteZipData(String routeId) async {
    return await _zipManager.removeRouteData(routeId);
  }

  /// Obtém estatísticas do sync offline
  Map<String, dynamic> getSyncStats() {
    final zipStats = _zipManager.getStats();
    final downloadStats = _downloader.getDownloadStats();
    
    return {
      'cachedUrls': _urlCache.length,
      'platform': kIsWeb ? 'web' : 'mobile',
      'supportsOffline': !kIsWeb,
      'zipManager': zipStats,
      'downloader': downloadStats,
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

  Future<void> dispose() async {
    _urlCache.clear();
    await _downloader.dispose();
    await _zipManager.dispose();
  }
}

/// Entry de cache para URLs da API
class _UrlCacheEntry {
  final String url;
  final DateTime expiresAt;

  _UrlCacheEntry(this.url, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}