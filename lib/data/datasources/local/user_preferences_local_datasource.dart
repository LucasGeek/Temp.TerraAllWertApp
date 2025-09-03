import '../../../domain/entities/user_preferences.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class UserPreferencesLocalDataSource {
  Future<List<UserPreferences>> getAll();
  Future<UserPreferences?> getById(String id);
  Future<UserPreferences?> getByUserId(String userId);
  Future<void> save(UserPreferences preferences);
  Future<void> saveAll(List<UserPreferences> preferencesList);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<UserPreferences>> getModified();
  Future<void> updateSyncStatus(String localId, String remoteId);
  Future<Map<String, dynamic>> getCurrentUserPreferences();
}

class UserPreferencesLocalDataSourceImpl implements UserPreferencesLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'user_preferences';
  
  UserPreferencesLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<UserPreferences>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      return data?.map((json) => UserPreferences.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<UserPreferences?> getById(String id) async {
    try {
      final preferencesList = await getAll();
      return preferencesList.where((prefs) => prefs.localId == id || prefs.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<UserPreferences?> getByUserId(String userId) async {
    try {
      final preferencesList = await getAll();
      return preferencesList.where((prefs) => prefs.userLocalId == userId).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> save(UserPreferences preferences) async {
    try {
      final preferencesList = await getAll();
      final index = preferencesList.indexWhere((p) => p.localId == preferences.localId);
      
      if (index >= 0) {
        preferencesList[index] = preferences;
      } else {
        preferencesList.add(preferences);
      }
      
      final jsonList = preferencesList.map((prefs) => prefs.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<UserPreferences> preferencesList) async {
    try {
      final jsonList = preferencesList.map((prefs) => prefs.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save user preferences list: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final preferencesList = await getAll();
      preferencesList.removeWhere((prefs) => prefs.localId == id || prefs.remoteId == id);
      
      final jsonList = preferencesList.map((prefs) => prefs.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<List<UserPreferences>> getModified() async {
    try {
      final preferencesList = await getAll();
      return preferencesList.where((prefs) => prefs.isModified).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    try {
      final preferences = await getById(localId);
      if (preferences != null) {
        final updatedPrefs = preferences.copyWith(
          remoteId: remoteId,
          isModified: false,
          lastModifiedAt: DateTime.now(),
        );
        await save(updatedPrefs);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getCurrentUserPreferences() async {
    try {
      // This would typically get preferences for current logged-in user
      // For now, return the first preferences found or empty map
      final preferencesList = await getAll();
      if (preferencesList.isNotEmpty) {
        return preferencesList.first.preferences ?? <String, dynamic>{};
      }
      return <String, dynamic>{};
    } catch (e) {
      return <String, dynamic>{};
    }
  }
}