abstract class MenuConfigRepository {
  // Basic CRUD operations
  Future<Map<String, dynamic>> getConfig(String menuLocalId);
  Future<void> updateConfig(String menuLocalId, Map<String, dynamic> config);
  Future<void> resetConfig(String menuLocalId);
  
  // Specific configuration operations
  Future<void> setTheme(String menuLocalId, String theme);
  Future<void> setLayout(String menuLocalId, String layout);
  Future<void> setDisplayOptions(String menuLocalId, Map<String, bool> options);
  Future<void> setNavigationConfig(String menuLocalId, Map<String, dynamic> navConfig);
  
  // Configuration queries
  Future<String> getTheme(String menuLocalId);
  Future<String> getLayout(String menuLocalId);
  Future<Map<String, bool>> getDisplayOptions(String menuLocalId);
  Future<Map<String, dynamic>> getNavigationConfig(String menuLocalId);
  
  // Sync operations
  Future<void> syncFromRemote(String menuLocalId);
  Future<void> syncToRemote(String menuLocalId);
  
  // Local operations
  Future<void> clearLocal();
  Future<Map<String, dynamic>> exportConfig(String menuLocalId);
  Future<void> importConfig(String menuLocalId, Map<String, dynamic> config);
}