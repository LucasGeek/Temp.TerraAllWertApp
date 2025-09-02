import 'dart:async';

import '../../domain/entities/user.dart';
import '../../domain/services/post_login_sync_service.dart';
import '../../infra/cache/cache_service.dart';
import '../../infra/graphql/menu_service.dart';
import '../../infra/sync/offline_sync_service.dart';
import '../../infra/logging/app_logger.dart';
import '../../infra/storage/menu_storage_service.dart';
import '../../infra/graphql/graphql_client.dart';
import '../../infra/graphql/mutations/file_upload_mutations.dart';
import 'package:graphql/client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostLoginSyncServiceImpl implements PostLoginSyncService {
  final MenuGraphQLService _menuService;
  final MenuStorageService _menuStorageService;
  final GraphQLClientService _graphqlClient;
  final OfflineSyncService _syncService;

  PostLoginSyncServiceImpl({
    required CacheService cacheService,
    required MenuGraphQLService menuService,
    required OfflineSyncService syncService,
    required MenuStorageService menuStorageService,
    required GraphQLClientService graphqlClient,
  }) : _menuService = menuService,
       _menuStorageService = menuStorageService,
       _graphqlClient = graphqlClient,
       _syncService = syncService;

  @override
  Future<PostLoginSyncResult> executeSyncFlow({
    required User user,
    required bool isOnline,
    required bool isWeb,
  }) async {
    AppLogger.info('Starting post-login sync flow for user: ${user.email}', tag: 'PostLoginSync');
    final startTime = DateTime.now();

    try {
      // 1. Verificar atualizações de arquivos
      AppLogger.debug('Step 1: Checking file updates', tag: 'PostLoginSync');
      final fileUpdateInfo = await checkFileUpdates(
        userId: user.id,
        isOnline: isOnline,
      );

      // 2. Baixar arquivos atualizados se necessário
      FileDownloadResult? downloadResult;
      if (fileUpdateInfo.hasUpdates && isOnline) {
        AppLogger.debug('Step 2: Downloading ${fileUpdateInfo.updatedFileIds.length} updated files', tag: 'PostLoginSync');
        downloadResult = await downloadUpdatedFiles(
          fileIds: fileUpdateInfo.updatedFileIds,
          userId: user.id,
        );
      } else {
        AppLogger.debug('Step 2: Skipped - No updates or offline', tag: 'PostLoginSync');
      }

      // 3. Sincronizar menus
      AppLogger.debug('Step 3: Syncing menus', tag: 'PostLoginSync');
      final menuResult = await syncMenus(
        userId: user.id,
        isOnline: isOnline,
      );

      final completedAt = DateTime.now();
      final duration = completedAt.difference(startTime);

      AppLogger.info('Post-login sync completed in ${duration.inMilliseconds}ms', tag: 'PostLoginSync');

      return PostLoginSyncResult(
        success: true,
        fileUpdateInfo: fileUpdateInfo,
        downloadResult: downloadResult,
        menuResult: menuResult,
        completedAt: completedAt,
      );

    } catch (e) {
      AppLogger.error('Post-login sync failed: $e', tag: 'PostLoginSync');
      
      return PostLoginSyncResult(
        success: false,
        error: e.toString(),
        fileUpdateInfo: FileUpdateInfo.empty(),
        menuResult: MenuSyncResult(
          success: false,
          source: MenuSyncSource.fallback,
          menuCount: 0,
          error: e.toString(),
          syncedAt: DateTime.now(),
        ),
        completedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<FileUpdateInfo> checkFileUpdates({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      if (!isOnline) {
        AppLogger.debug('Offline - skipping file update check', tag: 'PostLoginSync');
        return FileUpdateInfo.empty();
      }

      // Verificar atualizações via GraphQL API
      AppLogger.debug('Checking for file updates via GraphQL API', tag: 'PostLoginSync');
      
      try {
        // Usar getSyncMetadataQuery para verificar atualizações
        final result = await _graphqlClient.query(
          QueryOptions(
            document: gql(getSyncMetadataQuery),
            variables: {
              'routeId': userId, // Usar userId como routeId
            },
          ),
        );

        if (result.hasException) {
          AppLogger.warning('GraphQL error checking updates, falling back to timestamp check: ${result.exception}', tag: 'PostLoginSync');
          // Fallback para verificação por timestamp
          return await _checkUpdatesByTimestamp(userId);
        }

        final syncMetadata = result.data?['getSyncMetadata'];
        if (syncMetadata != null && syncMetadata['error'] == null) {
          // Verificar se há atualizações baseado na versão
          final lastSyncTime = await _getLastSyncTime(userId);
          final remoteVersion = syncMetadata['version'] as String?;
          final remoteLastModified = DateTime.tryParse(syncMetadata['lastModified'] as String? ?? '');
          final fileCount = syncMetadata['fileCount'] as int? ?? 0;
          final totalSize = syncMetadata['totalSize'] as int? ?? 0;
          
          final hasUpdates = lastSyncTime == null || 
              (remoteLastModified != null && remoteLastModified.isAfter(lastSyncTime));

          if (hasUpdates && fileCount > 0) {
            AppLogger.info('File updates available from API - version: $remoteVersion, files: $fileCount', tag: 'PostLoginSync');
            return FileUpdateInfo(
              hasUpdates: true,
              updatedFileIds: ['sync_metadata'], 
              totalFiles: fileCount,
              totalSizeBytes: totalSize,
              lastCheck: DateTime.now(),
            );
          }
        }

        AppLogger.debug('No file updates needed from API', tag: 'PostLoginSync');
        return FileUpdateInfo.empty();
        
      } catch (e) {
        AppLogger.warning('Exception checking updates via API, falling back to timestamp: $e', tag: 'PostLoginSync');
        return await _checkUpdatesByTimestamp(userId);
      }

    } catch (e) {
      AppLogger.warning('Failed to check file updates: $e', tag: 'PostLoginSync');
      return FileUpdateInfo.empty();
    }
  }

  @override
  Future<FileDownloadResult> downloadUpdatedFiles({
    required List<String> fileIds,
    required String userId,
  }) async {
    final startTime = DateTime.now();
    int downloadedFiles = 0;
    int failedFiles = 0;
    List<String> errors = [];

    try {
      AppLogger.info('Starting download of ${fileIds.length} files', tag: 'PostLoginSync');

      for (final fileId in fileIds) {
        try {
          AppLogger.debug('Downloading file: $fileId', tag: 'PostLoginSync');
          
          // Download real via sync service
          final downloadResult = await _syncService.downloadFileForOffline(
            fileId: fileId,
            routeId: userId,
            originalFileName: '$fileId.dat',
            onProgress: (progress) {
              AppLogger.debug('Download progress for $fileId: ${((progress?.progress ?? 0.0) * 100).toInt()}%', tag: 'PostLoginSync');
            },
          );
          
          if (downloadResult['success'] == true) {
            downloadedFiles++;
            AppLogger.debug('Downloaded file: $fileId', tag: 'PostLoginSync');
          } else {
            throw Exception(downloadResult['error'] ?? 'Unknown download error');
          }
          
        } catch (e) {
          failedFiles++;
          final error = 'Failed to download $fileId: $e';
          errors.add(error);
          AppLogger.error(error, tag: 'PostLoginSync');
        }
      }

      // Atualizar timestamp da última sincronização
      await _updateLastSyncTime(userId);

      final downloadTime = DateTime.now().difference(startTime);
      AppLogger.info('Download completed: $downloadedFiles success, $failedFiles failed in ${downloadTime.inMilliseconds}ms', tag: 'PostLoginSync');

      return FileDownloadResult(
        success: failedFiles == 0,
        downloadedFiles: downloadedFiles,
        failedFiles: failedFiles,
        errors: errors,
        downloadTime: downloadTime,
      );

    } catch (e) {
      AppLogger.error('File download process failed: $e', tag: 'PostLoginSync');
      
      return FileDownloadResult(
        success: false,
        downloadedFiles: downloadedFiles,
        failedFiles: fileIds.length - downloadedFiles,
        errors: [...errors, e.toString()],
        downloadTime: DateTime.now().difference(startTime),
      );
    }
  }

  @override
  Future<MenuSyncResult> syncMenus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      if (isOnline) {
        AppLogger.debug('Online - fetching menus from API', tag: 'PostLoginSync');
        
        try {
          // Tentar buscar da API primeiro usando routeId padrão
          final menus = await _menuService.getMenus(routeId: 'main');
          
          // Salvar menus no storage local para uso offline
          if (menus.isNotEmpty) {
            try {
              await _menuStorageService.saveNavigationItems(menus);
              AppLogger.debug('Menus saved to local storage successfully', tag: 'PostLoginSync');
            } catch (storageError) {
              AppLogger.warning('Failed to save menus to storage, but API fetch succeeded: $storageError', tag: 'PostLoginSync');
            }
          }
          
          AppLogger.info('Successfully fetched ${menus.length} menus from API', tag: 'PostLoginSync');
          
          return MenuSyncResult(
            success: true,
            source: MenuSyncSource.api,
            menuCount: menus.length,
            syncedAt: DateTime.now(),
          );
          
        } catch (e) {
          AppLogger.warning('API menu fetch failed, falling back to cache: $e', tag: 'PostLoginSync');
          
          // Fallback para cache se API falhar
          return await _getMenusFromCache();
        }
        
      } else {
        AppLogger.debug('Offline - using cached menus', tag: 'PostLoginSync');
        
        // Offline: usar cache
        return await _getMenusFromCache();
      }
      
    } catch (e) {
      AppLogger.error('Menu sync failed: $e', tag: 'PostLoginSync');
      
      return MenuSyncResult(
        success: false,
        source: MenuSyncSource.fallback,
        menuCount: 0,
        error: e.toString(),
        syncedAt: DateTime.now(),
      );
    }
  }

  /// Obtém menus do cache local
  Future<MenuSyncResult> _getMenusFromCache() async {
    try {
      // Buscar menus do storage local
      final cachedMenus = await _menuStorageService.loadNavigationItems();
      
      if (cachedMenus.isNotEmpty) {
        AppLogger.info('Using ${cachedMenus.length} cached menus from local storage', tag: 'PostLoginSync');
        
        return MenuSyncResult(
          success: true,
          source: MenuSyncSource.cache,
          menuCount: cachedMenus.length,
          syncedAt: DateTime.now(),
        );
      } else {
        AppLogger.debug('No cached menus found in local storage', tag: 'PostLoginSync');
        
        return MenuSyncResult(
          success: true,
          source: MenuSyncSource.fallback,
          menuCount: 0,
          syncedAt: DateTime.now(),
        );
      }
      
    } catch (e) {
      AppLogger.error('Cache menu fetch failed: $e', tag: 'PostLoginSync');
      
      return MenuSyncResult(
        success: false,
        source: MenuSyncSource.fallback,
        menuCount: 0,
        error: e.toString(),
        syncedAt: DateTime.now(),
      );
    }
  }

  /// Obtém timestamp da última sincronização
  Future<DateTime?> _getLastSyncTime(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'post_login_sync_timestamp_$userId';
      
      final timestampString = prefs.getString(syncKey);
      
      if (timestampString != null) {
        final timestamp = DateTime.tryParse(timestampString);
        if (timestamp != null) {
          AppLogger.debug('Retrieved last sync time for user $userId: $timestamp', tag: 'PostLoginSync');
          return timestamp;
        }
      }
      
      AppLogger.debug('No sync timestamp found for user: $userId', tag: 'PostLoginSync');
      return null; // Primeira vez
    } catch (e) {
      AppLogger.warning('Failed to get last sync time: $e', tag: 'PostLoginSync');
      return null;
    }
  }

  /// Atualiza timestamp da última sincronização
  Future<void> _updateLastSyncTime(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncKey = 'post_login_sync_timestamp_$userId';
      final currentTime = DateTime.now();
      
      await prefs.setString(syncKey, currentTime.toIso8601String());
      
      AppLogger.debug('Updated last sync time for user $userId: $currentTime', tag: 'PostLoginSync');
    } catch (e) {
      AppLogger.warning('Failed to update last sync time: $e', tag: 'PostLoginSync');
    }
  }

  /// Fallback: verifica atualizações por timestamp
  Future<FileUpdateInfo> _checkUpdatesByTimestamp(String userId) async {
    try {
      final lastSyncTime = await _getLastSyncTime(userId);
      final now = DateTime.now();
      
      // Se passou mais de 1 hora desde a última sync, assumir que há atualizações
      final hasUpdates = lastSyncTime == null || 
          now.difference(lastSyncTime).inHours >= 1;

      if (hasUpdates) {
        AppLogger.info('File updates detected by timestamp - last sync: $lastSyncTime', tag: 'PostLoginSync');
        return FileUpdateInfo(
          hasUpdates: true,
          updatedFileIds: ['timestamp_check'], 
          totalFiles: 1,
          totalSizeBytes: 102400, // 100KB estimado
          lastCheck: now,
        );
      }

      AppLogger.debug('No updates needed by timestamp check', tag: 'PostLoginSync');
      return FileUpdateInfo.empty();
    } catch (e) {
      AppLogger.error('Failed timestamp check: $e', tag: 'PostLoginSync');
      return FileUpdateInfo.empty();
    }
  }
}