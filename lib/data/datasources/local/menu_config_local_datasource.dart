import '../../../infra/storage/local_storage_adapter.dart';

abstract class MenuConfigLocalDataSource {
  Future<Map<String, dynamic>?> getConfig(String menuLocalId);
  Future<void> saveConfig(String menuLocalId, Map<String, dynamic> config);
  Future<void> deleteConfig(String menuLocalId);
  Future<void> clear();
  Future<List<String>> getAllMenuIds();
}

class MenuConfigLocalDataSourceImpl implements MenuConfigLocalDataSource {
  final LocalStorageAdapter _storage;
  static const String _keyPrefix = 'menu_config_';
  
  MenuConfigLocalDataSourceImpl(this._storage);
  
  String _getKey(String menuLocalId) => '$_keyPrefix$menuLocalId';
  
  @override
  Future<Map<String, dynamic>?> getConfig(String menuLocalId) async {
    try {
      final key = _getKey(menuLocalId);
      final data = _storage.getJsonMap(key);
      return data;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> saveConfig(String menuLocalId, Map<String, dynamic> config) async {
    try {
      final key = _getKey(menuLocalId);
      final configWithTimestamp = {
        ...config,
        'lastModifiedAt': DateTime.now().toIso8601String(),
      };
      await _storage.saveJsonMap(key, configWithTimestamp);
    } catch (e) {
      throw Exception('Failed to save menu config: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteConfig(String menuLocalId) async {
    try {
      final key = _getKey(menuLocalId);
      await _storage.remove(key);
    } catch (e) {
      throw Exception('Failed to delete menu config: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      // Get all keys and remove those starting with our prefix
      final allKeys = await getAllMenuIds();
      for (final menuId in allKeys) {
        await deleteConfig(menuId);
      }
    } catch (e) {
      throw Exception('Failed to clear menu configs: ${e.toString()}');
    }
  }
  
  @override
  Future<List<String>> getAllMenuIds() async {
    try {
      // This is a simplified implementation
      // In a real scenario, you'd need to iterate through storage keys
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }
}