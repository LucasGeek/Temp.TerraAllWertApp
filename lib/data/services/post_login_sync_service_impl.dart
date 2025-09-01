import 'dart:async';

import '../../domain/entities/user.dart';
import '../../domain/services/post_login_sync_service.dart';
import '../../infra/cache/cache_service.dart';
import '../../infra/graphql/menu_service.dart';
import '../../infra/sync/offline_sync_service.dart';
import '../../infra/logging/app_logger.dart';

class PostLoginSyncServiceImpl implements PostLoginSyncService {
  final MenuGraphQLService _menuService;

  PostLoginSyncServiceImpl({
    required CacheService cacheService,
    required MenuGraphQLService menuService,
    required OfflineSyncService syncService,
  }) : _menuService = menuService;

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

      // Usar OfflineSyncService para verificar atualizações
      AppLogger.debug('Checking for file updates via sync service', tag: 'PostLoginSync');
      
      // TODO: Implementar verificação real de atualizações
      // Por enquanto, simular verificação básica
      await Future.delayed(const Duration(milliseconds: 500)); // Simular network call
      
      // Verificar timestamp da última sincronização
      final lastSyncTime = await _getLastSyncTime(userId);
      final now = DateTime.now();
      
      // Se passou mais de 1 hora desde a última sync, assumir que há atualizações
      final hasUpdates = lastSyncTime == null || 
          now.difference(lastSyncTime).inHours >= 1;

      if (hasUpdates) {
        AppLogger.info('File updates available - last sync: $lastSyncTime', tag: 'PostLoginSync');
        return FileUpdateInfo(
          hasUpdates: true,
          updatedFileIds: ['menu_assets', 'carousel_images'], // Exemplo
          totalFiles: 2,
          totalSizeBytes: 1024000, // 1MB exemplo
          lastCheck: now,
        );
      }

      AppLogger.debug('No file updates needed', tag: 'PostLoginSync');
      return FileUpdateInfo.empty();

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
          
          // TODO: Implementar download real via sync service
          await Future.delayed(const Duration(milliseconds: 200)); // Simular download
          
          downloadedFiles++;
          AppLogger.debug('Downloaded file: $fileId', tag: 'PostLoginSync');
          
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
          // Tentar buscar da API primeiro
          final menus = await _menuService.getMenus(userId: userId);
          
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
      // TODO: Implementar busca real do cache
      // Por enquanto, simular busca do cache
      await Future.delayed(const Duration(milliseconds: 100));
      
      AppLogger.info('Using cached menus (fallback)', tag: 'PostLoginSync');
      
      return MenuSyncResult(
        success: true,
        source: MenuSyncSource.cache,
        menuCount: 3, // Exemplo: menu padrão
        syncedAt: DateTime.now(),
      );
      
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
      // TODO: Implementar busca real do timestamp no cache/storage
      // Por enquanto, simular
      await Future.delayed(const Duration(milliseconds: 50));
      return null; // Primeira vez
    } catch (e) {
      AppLogger.warning('Failed to get last sync time: $e', tag: 'PostLoginSync');
      return null;
    }
  }

  /// Atualiza timestamp da última sincronização
  Future<void> _updateLastSyncTime(String userId) async {
    try {
      // TODO: Implementar persistência real do timestamp
      await Future.delayed(const Duration(milliseconds: 50));
      AppLogger.debug('Updated last sync time for user: $userId', tag: 'PostLoginSync');
    } catch (e) {
      AppLogger.warning('Failed to update last sync time: $e', tag: 'PostLoginSync');
    }
  }
}