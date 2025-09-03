import '../../repositories/sync_repository.dart';
import '../../repositories/enterprise_repository.dart';
import '../../repositories/menu_repository.dart';
import '../../repositories/tower_repository.dart';
import '../../entities/menu.dart';

class SyncAllDataUseCase {
  final SyncRepository _syncRepository;
  final EnterpriseRepository _enterpriseRepository;
  final MenuRepository _menuRepository;
  final TowerRepository _towerRepository;

  SyncAllDataUseCase(
    this._syncRepository,
    this._enterpriseRepository,
    this._menuRepository,
    this._towerRepository,
  );

  Future<void> execute({
    bool forceSync = false,
    Function(String)? onProgress,
  }) async {
    try {
      // Check connectivity
      if (!await _syncRepository.isOnline()) {
        throw Exception('No internet connection');
      }
      
      // Check if sync is needed
      if (!forceSync) {
        final lastSync = await _syncRepository.getLastSyncTime('all');
        if (lastSync != null) {
          final timeSinceSync = DateTime.now().difference(lastSync);
          if (timeSinceSync.inMinutes < 5) {
            onProgress?.call('Data is already up to date');
            return;
          }
        }
      }
      
      onProgress?.call('Syncing enterprises...');
      await _enterpriseRepository.syncWithRemote();
      
      onProgress?.call('Syncing menus...');
      final enterprises = await _enterpriseRepository.getAllLocal();
      for (final enterprise in enterprises) {
        if (enterprise.remoteId != null) {
          await _menuRepository.syncWithRemote(enterprise.remoteId!);
        }
      }
      
      onProgress?.call('Syncing towers and properties...');
      final menus = await _menuRepository.getByEnterpriseIdLocal(
        enterprises.first.localId,
      );
      for (final menu in menus) {
        if (menu.screenType == ScreenType.floorplan && menu.remoteId != null) {
          await _towerRepository.syncTowersWithRemote(menu.remoteId!);
        }
      }
      
      onProgress?.call('Processing sync queue...');
      await _syncRepository.syncAll();
      
      // Update last sync time
      await _syncRepository.updateLastSyncTime('all', DateTime.now());
      
      onProgress?.call('Sync completed successfully');
    } catch (e) {
      throw Exception('Sync failed: ${e.toString()}');
    }
  }
}