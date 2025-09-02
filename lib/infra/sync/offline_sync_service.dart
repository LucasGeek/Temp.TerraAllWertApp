import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../graphql/graphql_client.dart';
import '../graphql/mutations/file_upload_mutations.dart';
import '../logging/app_logger.dart';
import '../downloads/background_download_service.dart';
import 'zip_manager.dart';
import 'package:graphql/client.dart';

/// Serviço de sincronização offline que gerencia URLs da API e fallback ZIP
class OfflineSyncService {
  final GraphQLClientService _graphqlClient;
  final BackgroundDownloadService _downloader = BackgroundDownloadService();
  final ZipManager _zipManager = ZipManager();

  // Cache de URLs da API para evitar chamadas desnecessárias
  final Map<String, _UrlCacheEntry> _urlCache = {};
  
  // Mapeamento de fileId para taskId para tracking de downloads
  final Map<String, String> _fileIdToTaskId = {};
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
    Function(dynamic)? onDownloadProgress,
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

      AppLogger.debug('Getting API URL for file: $fileId', tag: 'OfflineSync');
      
      // Real API integration
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
      
      return null;

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

      AppLogger.debug('Getting batch API URLs for ${fileIds.length} files', tag: 'OfflineSync');
      
      // Real API integration for batch downloads
      final queryResult = await _graphqlClient.query(
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

      if (!queryResult.hasException && queryResult.data?['getSignedDownloadUrls'] != null) {
        final urls = queryResult.data!['getSignedDownloadUrls']['urls'] as List?;
        
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
        // Buscar URL do ZIP via GraphQL API real
        try {
          AppLogger.debug('Requesting bulk download ZIP from API for route: $routeId', tag: 'OfflineSync');
          
          final result = await _graphqlClient.query(
            QueryOptions(
              document: gql(generateBulkDownloadQuery),
              variables: {
                'towerId': routeId, // Usando routeId como towerId
              },
            ),
          );

          if (result.hasException) {
            AppLogger.error('GraphQL error requesting ZIP: ${result.exception}', tag: 'OfflineSync');
            // Fallback para mock em caso de erro da API
            AppLogger.warning('Falling back to mock ZIP URL due to API error', tag: 'OfflineSync');
            effectiveZipUrl = 'https://api.example.com/routes/$routeId/download.zip';
          } else {
            final bulkDownload = result.data?['generateBulkDownload'];
            if (bulkDownload != null) {
              effectiveZipUrl = bulkDownload['downloadUrl'] as String?;
              effectiveVersion = bulkDownload['createdAt'] as String? ?? effectiveVersion;
              
              AppLogger.info('Successfully obtained ZIP URL from API: ${effectiveZipUrl?.substring(0, 50)}...', tag: 'OfflineSync');
            } else {
              AppLogger.warning('No bulk download data returned from API, using mock', tag: 'OfflineSync');
              effectiveZipUrl = 'https://api.example.com/routes/$routeId/download.zip';
            }
          }
        } catch (e) {
          AppLogger.error('Exception while requesting ZIP URL: $e', tag: 'OfflineSync');
          // Fallback para mock em caso de exception
          effectiveZipUrl = 'https://api.example.com/routes/$routeId/download.zip';
        }
      }

      // Garantir que effectiveZipUrl sempre tenha valor
      if (effectiveZipUrl == null) {
        AppLogger.error('No ZIP URL available after all attempts', tag: 'OfflineSync');
        return ZipDownloadResult(
          success: false,
          error: 'No ZIP URL available',
        );
      }

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
    Function(dynamic)? onProgress,
  }) async {
    try {
      AppLogger.info('Starting background download for offline cache: $fileId', tag: 'OfflineSync');
      
      // Inicializar serviço se necessário
      await _downloader.initialize();

      // Iniciar download assíncrono em background
      final taskId = await _downloader.startDownload(
        url: apiUrl,
        filename: originalFileName,
        directory: 'offline_files/$routeId',
        metadata: fileId,
        allowPause: true,
        requiresWiFi: false,
        retries: 3,
      );

      // Mapear fileId para taskId
      _fileIdToTaskId[fileId] = taskId;

      // Configurar streams de progresso e status se callback fornecido
      if (onProgress != null) {
        final progressStream = _downloader.getProgressStream(taskId);
        final statusStream = _downloader.getStatusStream(taskId);

        // Escutar progresso
        progressStream?.listen((progress) {
          AppLogger.debug(
            'Downloading $fileId: ${progress.formattedProgress}',
            tag: 'OfflineSync',
          );
          onProgress.call(progress);
        });

        // Escutar status final
        statusStream?.listen((status) {
          if (status == DownloadStatus.completed) {
            AppLogger.info('Background download completed: $fileId', tag: 'OfflineSync');
          } else if (status == DownloadStatus.failed) {
            AppLogger.error('Background download failed: $fileId', tag: 'OfflineSync');
          }
        });
      }

    } catch (e) {
      AppLogger.error('Failed to start background download: $fileId -> $e', tag: 'OfflineSync');
    }
  }

  /// Força download de arquivo específico com progresso
  Future<Map<String, dynamic>> downloadFileForOffline({
    required String fileId,
    required String routeId,
    String? originalFileName,
    Function(dynamic)? onProgress,
  }) async {
    if (kIsWeb) {
      AppLogger.warning('Offline download not supported on web', tag: 'OfflineSync');
      return {
        'success': false,
        'error': 'Offline downloads not supported on web platform',
      };
    }

    try {
      // Obter URL da API
      final apiUrl = await _getApiUrl(fileId: fileId, routeId: routeId);
      if (apiUrl == null) {
        return {
          'success': false,
          'error': 'Could not obtain API URL for download',
        };
      }

      // Inicializar serviço se necessário
      await _downloader.initialize();

      AppLogger.info('Starting forced download for offline: $fileId', tag: 'OfflineSync');

      // Iniciar download
      final taskId = await _downloader.startDownload(
        url: apiUrl,
        filename: originalFileName ?? '$fileId.dat',
        directory: 'offline_files/$routeId',
        metadata: fileId,
        allowPause: true,
        requiresWiFi: false,
        retries: 3,
      );

      // Mapear fileId para taskId
      _fileIdToTaskId[fileId] = taskId;

      // Configurar streams de progresso e status se callback fornecido
      if (onProgress != null) {
        final progressStream = _downloader.getProgressStream(taskId);
        progressStream?.listen((progress) {
          onProgress.call(progress);
        });
      }

      // Aguardar conclusão do download
      final statusStream = _downloader.getStatusStream(taskId);
      
      await for (final status in statusStream ?? const Stream.empty()) {
        if (status == DownloadStatus.completed) {
          AppLogger.info('Forced download completed: $fileId', tag: 'OfflineSync');
          final filePath = await _downloader.getDownloadedFilePath(taskId);
          return {
            'success': true,
            'filePath': filePath,
            'taskId': taskId,
          };
        } else if (status == DownloadStatus.failed) {
          return {
            'success': false,
            'error': 'Download failed for $fileId',
          };
        } else if (status == DownloadStatus.cancelled) {
          return {
            'success': false,
            'error': 'Download was cancelled for $fileId',
          };
        }
      }

      // Timeout ou stream vazio
      return {
        'success': false,
        'error': 'Download status unknown for $fileId',
      };

    } catch (e) {
      AppLogger.error('Forced download failed: $fileId -> $e', tag: 'OfflineSync');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Obtém stream de progresso de download
  Stream<dynamic>? getDownloadProgressStream(String fileId) {
    final taskId = _fileIdToTaskId[fileId];
    if (taskId == null) {
      AppLogger.warning('No taskId found for fileId: $fileId', tag: 'OfflineSync');
      return null;
    }
    return _downloader.getProgressStream(taskId);
  }

  /// Cancela download em progresso
  Future<bool> cancelDownload(String fileId) async {
    final taskId = _fileIdToTaskId[fileId];
    if (taskId == null) {
      AppLogger.warning('No taskId found for fileId: $fileId', tag: 'OfflineSync');
      return false;
    }
    
    final success = await _downloader.cancelDownload(taskId);
    if (success) {
      _fileIdToTaskId.remove(fileId);
    }
    return success;
  }

  /// Verifica se arquivo está sendo baixado
  Future<bool> isDownloading(String fileId) async {
    final taskId = _fileIdToTaskId[fileId];
    if (taskId == null) {
      return false;
    }
    
    try {
      final info = await _downloader.getDownloadInfo(taskId);
      return info != null && 
             (info.status == DownloadStatus.running || 
              info.status == DownloadStatus.enqueued ||
              info.status == DownloadStatus.retrying);
    } catch (e) {
      AppLogger.error('Error checking download status for $fileId: $e', tag: 'OfflineSync');
      return false;
    }
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
  Future<Map<String, dynamic>> getSyncStats() async {
    final zipStats = _zipManager.getStats();
    
    // Coletar stats dos downloads ativos
    Map<String, dynamic> downloadStats = {
      'activeDownloads': _fileIdToTaskId.length,
      'fileIdToTaskIdMappings': _fileIdToTaskId.length,
    };
    
    try {
      final activeDownloads = await _downloader.getActiveDownloads();
      downloadStats['totalActiveDownloads'] = activeDownloads.length;
      
      // Estatísticas detalhadas dos downloads ativos
      final downloadDetails = <String, dynamic>{};
      for (final taskId in activeDownloads) {
        try {
          final info = await _downloader.getDownloadInfo(taskId);
          if (info != null) {
            downloadDetails[taskId] = {
              'filename': info.filename,
              'status': info.status.toString(),
              'progress': info.progress,
              'expectedFileSize': info.expectedFileSize,
            };
          }
        } catch (e) {
          downloadDetails[taskId] = {'error': 'Failed to get info: $e'};
        }
      }
      downloadStats['downloadDetails'] = downloadDetails;
      
    } catch (e) {
      downloadStats['error'] = 'Failed to get download stats: $e';
    }
    
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
      
      // Limpar cache de URLs e mapeamento de downloads
      _urlCache.clear();
      _fileIdToTaskId.clear();
      
      AppLogger.info('Offline data cleared', tag: 'OfflineSync');
    } catch (e) {
      AppLogger.error('Failed to clear offline data: $e', tag: 'OfflineSync');
    }
  }

  Future<void> dispose() async {
    _urlCache.clear();
    _fileIdToTaskId.clear();
    _downloader.dispose(); // BackgroundDownloadService.dispose() returns void
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