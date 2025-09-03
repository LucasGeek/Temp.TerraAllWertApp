import '../../../infra/storage/preferences_adapter.dart';

abstract class PreferencesManagementLocalDataSource {
  // User-specific preferences
  Future<void> setUserPreference(String userId, String key, dynamic value);
  T? getUserPreference<T>(String userId, String key, [T? defaultValue]);
  Future<void> removeUserPreference(String userId, String key);
  Future<void> clearUserPreferences(String userId);
  
  // App-wide preferences
  Future<void> setAppPreference(String key, dynamic value);
  T? getAppPreference<T>(String key, [T? defaultValue]);
  Future<void> removeAppPreference(String key);
  
  // Theme & Display
  Future<void> setThemeMode(String themeMode);
  String getThemeMode([String defaultTheme = 'system']);
  Future<void> setLanguage(String languageCode);
  String getLanguage([String defaultLang = 'pt']);
  Future<void> setFontSize(double fontSize);
  double getFontSize([double defaultSize = 14.0]);
  
  // Sync preferences
  Future<void> setAutoSync(bool enabled);
  bool getAutoSync([bool defaultValue = true]);
  Future<void> setSyncInterval(int minutes);
  int getSyncInterval([int defaultMinutes = 30]);
  Future<void> setWifiOnlySync(bool enabled);
  bool getWifiOnlySync([bool defaultValue = false]);
  
  // Privacy & Security
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> getBiometricEnabled([bool defaultValue = false]);
  Future<void> setAutoLockEnabled(bool enabled);
  bool getAutoLockEnabled([bool defaultValue = false]);
  Future<void> setAutoLockTimeout(int minutes);
  int getAutoLockTimeout([int defaultMinutes = 5]);
  
  // Notification preferences
  Future<void> setPushNotificationsEnabled(bool enabled);
  bool getPushNotificationsEnabled([bool defaultValue = true]);
  Future<void> setSyncNotificationsEnabled(bool enabled);
  bool getSyncNotificationsEnabled([bool defaultValue = true]);
  Future<void> setErrorNotificationsEnabled(bool enabled);
  bool getErrorNotificationsEnabled([bool defaultValue = true]);
  
  // Cache preferences
  Future<void> setCacheEnabled(bool enabled);
  bool getCacheEnabled([bool defaultValue = true]);
  Future<void> setCacheSize(int sizeMB);
  int getCacheSize([int defaultSizeMB = 500]);
  Future<void> setImageQuality(String quality);
  String getImageQuality([String defaultQuality = 'high']);
  
  // Development preferences
  Future<void> setDebugMode(bool enabled);
  bool getDebugMode([bool defaultValue = false]);
  Future<void> setApiEndpoint(String endpoint);
  Future<String> getApiEndpoint([String defaultEndpoint = 'https://api.terraallwert.com']);
  
  // Secure storage
  Future<void> setSecurePreference(String key, String value);
  Future<String?> getSecurePreference(String key);
  Future<void> removeSecurePreference(String key);
  Future<void> clearSecurePreferences();
  
  // Utility methods
  Future<Map<String, dynamic>> getAllUserPreferences(String userId);
  Future<Map<String, dynamic>> getAllAppPreferences();
  Future<void> clearAllPreferences();
  Future<void> exportPreferences(String userId);
  Future<Map<String, dynamic>?> getLastExport();
}

class PreferencesManagementLocalDataSourceImpl implements PreferencesManagementLocalDataSource {
  final PreferencesAdapter _preferencesAdapter;
  
  PreferencesManagementLocalDataSourceImpl(this._preferencesAdapter);
  
  @override
  Future<void> setUserPreference(String userId, String key, dynamic value) async {
    try {
      await _preferencesAdapter.setUserPreference(userId, key, value);
    } catch (e) {
      throw Exception('Failed to set user preference: ${e.toString()}');
    }
  }
  
  @override
  T? getUserPreference<T>(String userId, String key, [T? defaultValue]) {
    try {
      return _preferencesAdapter.getUserPreference<T>(userId, key, defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> removeUserPreference(String userId, String key) async {
    try {
      await _preferencesAdapter.removeUserPreference(userId, key);
    } catch (e) {
      throw Exception('Failed to remove user preference: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearUserPreferences(String userId) async {
    try {
      await _preferencesAdapter.clearUserPreferences(userId);
    } catch (e) {
      throw Exception('Failed to clear user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> setAppPreference(String key, dynamic value) async {
    try {
      await _preferencesAdapter.setAppPreference(key, value);
    } catch (e) {
      throw Exception('Failed to set app preference: ${e.toString()}');
    }
  }
  
  @override
  T? getAppPreference<T>(String key, [T? defaultValue]) {
    try {
      return _preferencesAdapter.getAppPreference<T>(key, defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> removeAppPreference(String key) async {
    try {
      await _preferencesAdapter.removeAppPreference(key);
    } catch (e) {
      throw Exception('Failed to remove app preference: ${e.toString()}');
    }
  }
  
  @override
  Future<void> setThemeMode(String themeMode) async {
    try {
      await _preferencesAdapter.setThemeMode(themeMode);
    } catch (e) {
      throw Exception('Failed to set theme mode: ${e.toString()}');
    }
  }
  
  @override
  String getThemeMode([String defaultTheme = 'system']) {
    try {
      return _preferencesAdapter.getThemeMode(defaultTheme);
    } catch (e) {
      return defaultTheme;
    }
  }
  
  @override
  Future<void> setLanguage(String languageCode) async {
    try {
      await _preferencesAdapter.setLanguage(languageCode);
    } catch (e) {
      throw Exception('Failed to set language: ${e.toString()}');
    }
  }
  
  @override
  String getLanguage([String defaultLang = 'pt']) {
    try {
      return _preferencesAdapter.getLanguage(defaultLang);
    } catch (e) {
      return defaultLang;
    }
  }
  
  @override
  Future<void> setFontSize(double fontSize) async {
    try {
      await _preferencesAdapter.setFontSize(fontSize);
    } catch (e) {
      throw Exception('Failed to set font size: ${e.toString()}');
    }
  }
  
  @override
  double getFontSize([double defaultSize = 14.0]) {
    try {
      return _preferencesAdapter.getFontSize(defaultSize);
    } catch (e) {
      return defaultSize;
    }
  }
  
  @override
  Future<void> setAutoSync(bool enabled) async {
    try {
      await _preferencesAdapter.setAutoSync(enabled);
    } catch (e) {
      throw Exception('Failed to set auto sync: ${e.toString()}');
    }
  }
  
  @override
  bool getAutoSync([bool defaultValue = true]) {
    try {
      return _preferencesAdapter.getAutoSync(defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> setSyncInterval(int minutes) async {
    try {
      await _preferencesAdapter.setSyncInterval(minutes);
    } catch (e) {
      throw Exception('Failed to set sync interval: ${e.toString()}');
    }
  }
  
  @override
  int getSyncInterval([int defaultMinutes = 30]) {
    try {
      return _preferencesAdapter.getSyncInterval(defaultMinutes);
    } catch (e) {
      return defaultMinutes;
    }
  }
  
  @override
  Future<void> setWifiOnlySync(bool enabled) async {
    try {
      await _preferencesAdapter.setWifiOnlySync(enabled);
    } catch (e) {
      throw Exception('Failed to set wifi only sync: ${e.toString()}');
    }
  }
  
  @override
  bool getWifiOnlySync([bool defaultValue = false]) {
    try {
      return _preferencesAdapter.getWifiOnlySync(defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _preferencesAdapter.setBiometricEnabled(enabled);
    } catch (e) {
      throw Exception('Failed to set biometric enabled: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> getBiometricEnabled([bool defaultValue = false]) async {
    try {
      return await _preferencesAdapter.getBiometricEnabled(defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> setAutoLockEnabled(bool enabled) async {
    try {
      await _preferencesAdapter.setAutoLockEnabled(enabled);
    } catch (e) {
      throw Exception('Failed to set auto lock enabled: ${e.toString()}');
    }
  }
  
  @override
  bool getAutoLockEnabled([bool defaultValue = false]) {
    try {
      return _preferencesAdapter.getAutoLockEnabled(defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> setAutoLockTimeout(int minutes) async {
    try {
      await _preferencesAdapter.setAutoLockTimeout(minutes);
    } catch (e) {
      throw Exception('Failed to set auto lock timeout: ${e.toString()}');
    }
  }
  
  @override
  int getAutoLockTimeout([int defaultMinutes = 5]) {
    try {
      return _preferencesAdapter.getAutoLockTimeout(defaultMinutes);
    } catch (e) {
      return defaultMinutes;
    }
  }
  
  @override
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    try {
      await _preferencesAdapter.setPushNotificationsEnabled(enabled);
    } catch (e) {
      throw Exception('Failed to set push notifications enabled: ${e.toString()}');
    }
  }
  
  @override
  bool getPushNotificationsEnabled([bool defaultValue = true]) {
    try {
      return _preferencesAdapter.getPushNotificationsEnabled(defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> setSyncNotificationsEnabled(bool enabled) async {
    try {
      await _preferencesAdapter.setSyncNotificationsEnabled(enabled);
    } catch (e) {
      throw Exception('Failed to set sync notifications enabled: ${e.toString()}');
    }
  }
  
  @override
  bool getSyncNotificationsEnabled([bool defaultValue = true]) {
    try {
      return _preferencesAdapter.getSyncNotificationsEnabled(defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> setErrorNotificationsEnabled(bool enabled) async {
    try {
      await _preferencesAdapter.setErrorNotificationsEnabled(enabled);
    } catch (e) {
      throw Exception('Failed to set error notifications enabled: ${e.toString()}');
    }
  }
  
  @override
  bool getErrorNotificationsEnabled([bool defaultValue = true]) {
    try {
      return _preferencesAdapter.getErrorNotificationsEnabled(defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> setCacheEnabled(bool enabled) async {
    try {
      await _preferencesAdapter.setCacheEnabled(enabled);
    } catch (e) {
      throw Exception('Failed to set cache enabled: ${e.toString()}');
    }
  }
  
  @override
  bool getCacheEnabled([bool defaultValue = true]) {
    try {
      return _preferencesAdapter.getCacheEnabled(defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> setCacheSize(int sizeMB) async {
    try {
      await _preferencesAdapter.setCacheSize(sizeMB);
    } catch (e) {
      throw Exception('Failed to set cache size: ${e.toString()}');
    }
  }
  
  @override
  int getCacheSize([int defaultSizeMB = 500]) {
    try {
      return _preferencesAdapter.getCacheSize(defaultSizeMB);
    } catch (e) {
      return defaultSizeMB;
    }
  }
  
  @override
  Future<void> setImageQuality(String quality) async {
    try {
      await _preferencesAdapter.setImageQuality(quality);
    } catch (e) {
      throw Exception('Failed to set image quality: ${e.toString()}');
    }
  }
  
  @override
  String getImageQuality([String defaultQuality = 'high']) {
    try {
      return _preferencesAdapter.getImageQuality(defaultQuality);
    } catch (e) {
      return defaultQuality;
    }
  }
  
  @override
  Future<void> setDebugMode(bool enabled) async {
    try {
      await _preferencesAdapter.setDebugMode(enabled);
    } catch (e) {
      throw Exception('Failed to set debug mode: ${e.toString()}');
    }
  }
  
  @override
  bool getDebugMode([bool defaultValue = false]) {
    try {
      return _preferencesAdapter.getDebugMode(defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  @override
  Future<void> setApiEndpoint(String endpoint) async {
    try {
      await _preferencesAdapter.setApiEndpoint(endpoint);
    } catch (e) {
      throw Exception('Failed to set API endpoint: ${e.toString()}');
    }
  }
  
  @override
  Future<String> getApiEndpoint([String defaultEndpoint = 'https://api.terraallwert.com']) async {
    try {
      return await _preferencesAdapter.getApiEndpoint(defaultEndpoint);
    } catch (e) {
      return defaultEndpoint;
    }
  }
  
  @override
  Future<void> setSecurePreference(String key, String value) async {
    try {
      await _preferencesAdapter.setSecurePreference(key, value);
    } catch (e) {
      throw Exception('Failed to set secure preference: ${e.toString()}');
    }
  }
  
  @override
  Future<String?> getSecurePreference(String key) async {
    try {
      return await _preferencesAdapter.getSecurePreference(key);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> removeSecurePreference(String key) async {
    try {
      await _preferencesAdapter.removeSecurePreference(key);
    } catch (e) {
      throw Exception('Failed to remove secure preference: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearSecurePreferences() async {
    try {
      await _preferencesAdapter.clearSecurePreferences();
    } catch (e) {
      throw Exception('Failed to clear secure preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getAllUserPreferences(String userId) async {
    try {
      return await _preferencesAdapter.getAllUserPreferences(userId);
    } catch (e) {
      throw Exception('Failed to get all user preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getAllAppPreferences() async {
    try {
      return await _preferencesAdapter.getAllAppPreferences();
    } catch (e) {
      throw Exception('Failed to get all app preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearAllPreferences() async {
    try {
      await _preferencesAdapter.clearAllPreferences();
    } catch (e) {
      throw Exception('Failed to clear all preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<void> exportPreferences(String userId) async {
    try {
      await _preferencesAdapter.exportPreferences(userId);
    } catch (e) {
      throw Exception('Failed to export preferences: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getLastExport() async {
    try {
      return await _preferencesAdapter.getLastExport();
    } catch (e) {
      return null;
    }
  }
}