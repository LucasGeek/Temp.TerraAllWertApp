import '../entities/user_preferences.dart';

abstract class UserPreferencesRepository {
  // Basic CRUD operations
  Future<UserPreferences> create(UserPreferences preferences);
  Future<UserPreferences> update(UserPreferences preferences);
  Future<void> delete(String localId);
  Future<UserPreferences?> getById(String localId);
  Future<List<UserPreferences>> getAll();
  
  // Business-specific queries
  Future<UserPreferences?> getByUserId(String userLocalId);
  Future<Map<String, dynamic>> getCurrentUserPreferences();
  Future<T?> getPreference<T>(String key, T defaultValue);
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<UserPreferences>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  
  // Preference management
  Future<void> setPreference(String key, dynamic value);
  Future<void> removePreference(String key);
  Future<void> resetToDefaults();
  Future<Map<String, dynamic>> exportPreferences();
  Future<void> importPreferences(Map<String, dynamic> preferences);
}