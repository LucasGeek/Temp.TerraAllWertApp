import '../../domain/repositories/menu_config_repository.dart';
import '../datasources/local/menu_config_local_datasource.dart';
import '../datasources/remote/menu_config_remote_datasource.dart';

class MenuConfigRepositoryImpl implements MenuConfigRepository {
  final MenuConfigLocalDataSource _localDataSource;
  final MenuConfigRemoteDataSource _remoteDataSource;
  
  MenuConfigRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
  );
  
  @override
  Future<Map<String, dynamic>> getConfig(String menuLocalId) async {
    try {
      // Try local first
      final localConfig = await _localDataSource.getConfig(menuLocalId);
      if (localConfig != null) {
        return localConfig;
      }
      
      // Fallback to remote
      final remoteConfig = await _remoteDataSource.getConfig(menuLocalId);
      if (remoteConfig != null) {
        // Cache remote config locally
        await _localDataSource.saveConfig(menuLocalId, remoteConfig);
        return remoteConfig;
      }
      
      // Return default config
      return await _remoteDataSource.getDefaultConfig();
    } catch (e) {
      throw Exception('Failed to get menu config: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateConfig(String menuLocalId, Map<String, dynamic> config) async {
    try {
      // Save locally first
      await _localDataSource.saveConfig(menuLocalId, config);
      
      // Try to sync with remote
      try {
        await _remoteDataSource.updateConfig(menuLocalId, config);
      } catch (e) {
        // Remote sync failed, but local is saved
        // This will be synced later
      }
    } catch (e) {
      throw Exception('Failed to update menu config: ${e.toString()}');
    }
  }
  
  @override
  Future<void> resetConfig(String menuLocalId) async {
    try {
      // Delete local config
      await _localDataSource.deleteConfig(menuLocalId);
      
      // Try to reset remote config
      try {
        await _remoteDataSource.resetConfig(menuLocalId);
      } catch (e) {
        // Remote reset failed, but local is cleared
      }
    } catch (e) {
      throw Exception('Failed to reset menu config: ${e.toString()}');
    }
  }
  
  @override
  Future<void> setTheme(String menuLocalId, String theme) async {
    try {
      final currentConfig = await getConfig(menuLocalId);
      currentConfig['theme'] = theme;
      await updateConfig(menuLocalId, currentConfig);
    } catch (e) {
      throw Exception('Failed to set theme: ${e.toString()}');
    }
  }
  
  @override
  Future<void> setLayout(String menuLocalId, String layout) async {
    try {
      final currentConfig = await getConfig(menuLocalId);
      currentConfig['layout'] = layout;
      await updateConfig(menuLocalId, currentConfig);
    } catch (e) {
      throw Exception('Failed to set layout: ${e.toString()}');
    }
  }
  
  @override
  Future<void> setDisplayOptions(String menuLocalId, Map<String, bool> options) async {
    try {
      final currentConfig = await getConfig(menuLocalId);
      currentConfig['displayOptions'] = options;
      await updateConfig(menuLocalId, currentConfig);
    } catch (e) {
      throw Exception('Failed to set display options: ${e.toString()}');
    }
  }
  
  @override
  Future<void> setNavigationConfig(String menuLocalId, Map<String, dynamic> navConfig) async {
    try {
      final currentConfig = await getConfig(menuLocalId);
      currentConfig['navigationConfig'] = navConfig;
      await updateConfig(menuLocalId, currentConfig);
    } catch (e) {
      throw Exception('Failed to set navigation config: ${e.toString()}');
    }
  }
  
  @override
  Future<String> getTheme(String menuLocalId) async {
    try {
      final config = await getConfig(menuLocalId);
      return config['theme'] ?? 'light';
    } catch (e) {
      return 'light';
    }
  }
  
  @override
  Future<String> getLayout(String menuLocalId) async {
    try {
      final config = await getConfig(menuLocalId);
      return config['layout'] ?? 'grid';
    } catch (e) {
      return 'grid';
    }
  }
  
  @override
  Future<Map<String, bool>> getDisplayOptions(String menuLocalId) async {
    try {
      final config = await getConfig(menuLocalId);
      final displayOptions = config['displayOptions'] as Map<String, dynamic>?;
      return displayOptions?.cast<String, bool>() ?? {
        'showThumbnails': true,
        'showDescriptions': true,
        'showPrices': true,
      };
    } catch (e) {
      return {
        'showThumbnails': true,
        'showDescriptions': true,
        'showPrices': true,
      };
    }
  }
  
  @override
  Future<Map<String, dynamic>> getNavigationConfig(String menuLocalId) async {
    try {
      final config = await getConfig(menuLocalId);
      return config['navigationConfig'] as Map<String, dynamic>? ?? {
        'enableSwipeNavigation': true,
        'showNavigationDots': true,
        'autoAdvanceTime': 5000,
      };
    } catch (e) {
      return {
        'enableSwipeNavigation': true,
        'showNavigationDots': true,
        'autoAdvanceTime': 5000,
      };
    }
  }
  
  @override
  Future<void> syncFromRemote(String menuLocalId) async {
    try {
      final remoteConfig = await _remoteDataSource.getConfig(menuLocalId);
      if (remoteConfig != null) {
        await _localDataSource.saveConfig(menuLocalId, remoteConfig);
      }
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncToRemote(String menuLocalId) async {
    try {
      final localConfig = await _localDataSource.getConfig(menuLocalId);
      if (localConfig != null) {
        await _remoteDataSource.updateConfig(menuLocalId, localConfig);
      }
    } catch (e) {
      throw Exception('Failed to sync to remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local configs: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> exportConfig(String menuLocalId) async {
    try {
      return await getConfig(menuLocalId);
    } catch (e) {
      return {};
    }
  }
  
  @override
  Future<void> importConfig(String menuLocalId, Map<String, dynamic> config) async {
    try {
      await updateConfig(menuLocalId, config);
    } catch (e) {
      throw Exception('Failed to import config: ${e.toString()}');
    }
  }
}