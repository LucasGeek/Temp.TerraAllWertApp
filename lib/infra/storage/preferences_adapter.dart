import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesAdapter {
  static const String _keyPrefix = 'terra_allwert_prefs_';
  static const String _securePrefix = 'terra_allwert_secure_';
  
  late final SharedPreferences _sharedPrefs;
  late final FlutterSecureStorage _secureStorage;
  
  PreferencesAdapter._();
  
  static PreferencesAdapter? _instance;
  
  static Future<PreferencesAdapter> getInstance() async {
    if (_instance == null) {
      _instance = PreferencesAdapter._();
      await _instance!._initialize();
    }
    return _instance!;
  }
  
  Future<void> _initialize() async {
    _sharedPrefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }
  
  String _getKey(String key) => '$_keyPrefix$key';
  String _getSecureKey(String key) => '$_securePrefix$key';
  
  // ===== User Preferences =====
  
  Future<void> setUserPreference(String userId, String key, dynamic value) async {
    final prefKey = _getKey('user_${userId}_$key');
    
    if (value is String) {
      await _sharedPrefs.setString(prefKey, value);
    } else if (value is int) {
      await _sharedPrefs.setInt(prefKey, value);
    } else if (value is double) {
      await _sharedPrefs.setDouble(prefKey, value);
    } else if (value is bool) {
      await _sharedPrefs.setBool(prefKey, value);
    } else if (value is List<String>) {
      await _sharedPrefs.setStringList(prefKey, value);
    } else {
      // For complex objects, store as JSON
      await _sharedPrefs.setString(prefKey, jsonEncode(value));
    }
  }
  
  T? getUserPreference<T>(String userId, String key, [T? defaultValue]) {
    final prefKey = _getKey('user_${userId}_$key');
    
    if (T == String) {
      return _sharedPrefs.getString(prefKey) as T? ?? defaultValue;
    } else if (T == int) {
      return _sharedPrefs.getInt(prefKey) as T? ?? defaultValue;
    } else if (T == double) {
      return _sharedPrefs.getDouble(prefKey) as T? ?? defaultValue;
    } else if (T == bool) {
      return _sharedPrefs.getBool(prefKey) as T? ?? defaultValue;
    } else if (T == List<String>) {
      return _sharedPrefs.getStringList(prefKey) as T? ?? defaultValue;
    } else {
      // For complex objects, decode from JSON
      final jsonString = _sharedPrefs.getString(prefKey);
      if (jsonString != null) {
        try {
          return jsonDecode(jsonString) as T;
        } catch (_) {
          return defaultValue;
        }
      }
      return defaultValue;
    }
  }
  
  Future<void> removeUserPreference(String userId, String key) async {
    final prefKey = _getKey('user_${userId}_$key');
    await _sharedPrefs.remove(prefKey);
  }
  
  Future<void> clearUserPreferences(String userId) async {
    final keys = _sharedPrefs.getKeys();
    final userPrefix = _getKey('user_${userId}_');
    
    for (final key in keys) {
      if (key.startsWith(userPrefix)) {
        await _sharedPrefs.remove(key);
      }
    }
  }
  
  // ===== App Preferences =====
  
  Future<void> setAppPreference(String key, dynamic value) async {
    final prefKey = _getKey('app_$key');
    
    if (value is String) {
      await _sharedPrefs.setString(prefKey, value);
    } else if (value is int) {
      await _sharedPrefs.setInt(prefKey, value);
    } else if (value is double) {
      await _sharedPrefs.setDouble(prefKey, value);
    } else if (value is bool) {
      await _sharedPrefs.setBool(prefKey, value);
    } else if (value is List<String>) {
      await _sharedPrefs.setStringList(prefKey, value);
    } else {
      await _sharedPrefs.setString(prefKey, jsonEncode(value));
    }
  }
  
  T? getAppPreference<T>(String key, [T? defaultValue]) {
    final prefKey = _getKey('app_$key');
    
    if (T == String) {
      return _sharedPrefs.getString(prefKey) as T? ?? defaultValue;
    } else if (T == int) {
      return _sharedPrefs.getInt(prefKey) as T? ?? defaultValue;
    } else if (T == double) {
      return _sharedPrefs.getDouble(prefKey) as T? ?? defaultValue;
    } else if (T == bool) {
      return _sharedPrefs.getBool(prefKey) as T? ?? defaultValue;
    } else if (T == List<String>) {
      return _sharedPrefs.getStringList(prefKey) as T? ?? defaultValue;
    } else {
      final jsonString = _sharedPrefs.getString(prefKey);
      if (jsonString != null) {
        try {
          return jsonDecode(jsonString) as T;
        } catch (_) {
          return defaultValue;
        }
      }
      return defaultValue;
    }
  }
  
  Future<void> removeAppPreference(String key) async {
    final prefKey = _getKey('app_$key');
    await _sharedPrefs.remove(prefKey);
  }
  
  // ===== Theme & Display Preferences =====
  
  Future<void> setThemeMode(String themeMode) async {
    await setAppPreference('theme_mode', themeMode);
  }
  
  String getThemeMode([String defaultTheme = 'system']) {
    return getAppPreference<String>('theme_mode', defaultTheme) ?? defaultTheme;
  }
  
  Future<void> setLanguage(String languageCode) async {
    await setAppPreference('language', languageCode);
  }
  
  String getLanguage([String defaultLang = 'pt']) {
    return getAppPreference<String>('language', defaultLang) ?? defaultLang;
  }
  
  Future<void> setFontSize(double fontSize) async {
    await setAppPreference('font_size', fontSize);
  }
  
  double getFontSize([double defaultSize = 14.0]) {
    return getAppPreference<double>('font_size', defaultSize) ?? defaultSize;
  }
  
  // ===== Sync Preferences =====
  
  Future<void> setAutoSync(bool enabled) async {
    await setAppPreference('auto_sync', enabled);
  }
  
  bool getAutoSync([bool defaultValue = true]) {
    return getAppPreference<bool>('auto_sync', defaultValue) ?? defaultValue;
  }
  
  Future<void> setSyncInterval(int minutes) async {
    await setAppPreference('sync_interval', minutes);
  }
  
  int getSyncInterval([int defaultMinutes = 30]) {
    return getAppPreference<int>('sync_interval', defaultMinutes) ?? defaultMinutes;
  }
  
  Future<void> setWifiOnlySync(bool enabled) async {
    await setAppPreference('wifi_only_sync', enabled);
  }
  
  bool getWifiOnlySync([bool defaultValue = false]) {
    return getAppPreference<bool>('wifi_only_sync', defaultValue) ?? defaultValue;
  }
  
  // ===== Privacy & Security Preferences =====
  
  Future<void> setBiometricEnabled(bool enabled) async {
    await setSecurePreference('biometric_enabled', enabled.toString());
  }
  
  Future<bool> getBiometricEnabled([bool defaultValue = false]) async {
    final value = await getSecurePreference('biometric_enabled');
    return value == 'true' ? true : defaultValue;
  }
  
  Future<void> setAutoLockEnabled(bool enabled) async {
    await setAppPreference('auto_lock_enabled', enabled);
  }
  
  bool getAutoLockEnabled([bool defaultValue = false]) {
    return getAppPreference<bool>('auto_lock_enabled', defaultValue) ?? defaultValue;
  }
  
  Future<void> setAutoLockTimeout(int minutes) async {
    await setAppPreference('auto_lock_timeout', minutes);
  }
  
  int getAutoLockTimeout([int defaultMinutes = 5]) {
    return getAppPreference<int>('auto_lock_timeout', defaultMinutes) ?? defaultMinutes;
  }
  
  // ===== Notification Preferences =====
  
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    await setAppPreference('push_notifications', enabled);
  }
  
  bool getPushNotificationsEnabled([bool defaultValue = true]) {
    return getAppPreference<bool>('push_notifications', defaultValue) ?? defaultValue;
  }
  
  Future<void> setSyncNotificationsEnabled(bool enabled) async {
    await setAppPreference('sync_notifications', enabled);
  }
  
  bool getSyncNotificationsEnabled([bool defaultValue = true]) {
    return getAppPreference<bool>('sync_notifications', defaultValue) ?? defaultValue;
  }
  
  Future<void> setErrorNotificationsEnabled(bool enabled) async {
    await setAppPreference('error_notifications', enabled);
  }
  
  bool getErrorNotificationsEnabled([bool defaultValue = true]) {
    return getAppPreference<bool>('error_notifications', defaultValue) ?? defaultValue;
  }
  
  // ===== Cache Preferences =====
  
  Future<void> setCacheEnabled(bool enabled) async {
    await setAppPreference('cache_enabled', enabled);
  }
  
  bool getCacheEnabled([bool defaultValue = true]) {
    return getAppPreference<bool>('cache_enabled', defaultValue) ?? defaultValue;
  }
  
  Future<void> setCacheSize(int sizeMB) async {
    await setAppPreference('cache_size_mb', sizeMB);
  }
  
  int getCacheSize([int defaultSizeMB = 500]) {
    return getAppPreference<int>('cache_size_mb', defaultSizeMB) ?? defaultSizeMB;
  }
  
  Future<void> setImageQuality(String quality) async {
    await setAppPreference('image_quality', quality);
  }
  
  String getImageQuality([String defaultQuality = 'high']) {
    return getAppPreference<String>('image_quality', defaultQuality) ?? defaultQuality;
  }
  
  // ===== Development Preferences =====
  
  Future<void> setDebugMode(bool enabled) async {
    await setAppPreference('debug_mode', enabled);
  }
  
  bool getDebugMode([bool defaultValue = false]) {
    return getAppPreference<bool>('debug_mode', defaultValue) ?? defaultValue;
  }
  
  Future<void> setApiEndpoint(String endpoint) async {
    await setSecurePreference('api_endpoint', endpoint);
  }
  
  Future<String> getApiEndpoint([String defaultEndpoint = 'https://api.terraallwert.com']) async {
    return await getSecurePreference('api_endpoint') ?? defaultEndpoint;
  }
  
  // ===== Secure Storage Operations =====
  
  Future<void> setSecurePreference(String key, String value) async {
    final secureKey = _getSecureKey(key);
    await _secureStorage.write(key: secureKey, value: value);
  }
  
  Future<String?> getSecurePreference(String key) async {
    final secureKey = _getSecureKey(key);
    return await _secureStorage.read(key: secureKey);
  }
  
  Future<void> removeSecurePreference(String key) async {
    final secureKey = _getSecureKey(key);
    await _secureStorage.delete(key: secureKey);
  }
  
  Future<void> clearSecurePreferences() async {
    final allKeys = await _secureStorage.readAll();
    for (final key in allKeys.keys) {
      if (key.startsWith(_securePrefix)) {
        await _secureStorage.delete(key: key);
      }
    }
  }
  
  // ===== Utility Methods =====
  
  Future<Map<String, dynamic>> getAllUserPreferences(String userId) async {
    final allKeys = _sharedPrefs.getKeys();
    final userPrefix = _getKey('user_${userId}_');
    final Map<String, dynamic> userPrefs = {};
    
    for (final key in allKeys) {
      if (key.startsWith(userPrefix)) {
        final prefKey = key.substring(userPrefix.length);
        final value = _sharedPrefs.get(key);
        
        // Try to decode JSON values
        if (value is String) {
          try {
            userPrefs[prefKey] = jsonDecode(value);
          } catch (_) {
            userPrefs[prefKey] = value;
          }
        } else {
          userPrefs[prefKey] = value;
        }
      }
    }
    
    return userPrefs;
  }
  
  Future<Map<String, dynamic>> getAllAppPreferences() async {
    final allKeys = _sharedPrefs.getKeys();
    final appPrefix = _getKey('app_');
    final Map<String, dynamic> appPrefs = {};
    
    for (final key in allKeys) {
      if (key.startsWith(appPrefix)) {
        final prefKey = key.substring(appPrefix.length);
        final value = _sharedPrefs.get(key);
        
        // Try to decode JSON values
        if (value is String) {
          try {
            appPrefs[prefKey] = jsonDecode(value);
          } catch (_) {
            appPrefs[prefKey] = value;
          }
        } else {
          appPrefs[prefKey] = value;
        }
      }
    }
    
    return appPrefs;
  }
  
  Future<void> clearAllPreferences() async {
    // Clear all SharedPreferences with our prefix
    final allKeys = _sharedPrefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith(_keyPrefix)) {
        await _sharedPrefs.remove(key);
      }
    }
    
    // Clear all secure preferences
    await clearSecurePreferences();
  }
  
  Future<void> exportPreferences(String userId) async {
    final userPrefs = await getAllUserPreferences(userId);
    final appPrefs = await getAllAppPreferences();
    
    final exportData = {
      'userPreferences': userPrefs,
      'appPreferences': appPrefs,
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    
    // Store export in a special key
    await setAppPreference('last_export', exportData);
  }
  
  Future<Map<String, dynamic>?> getLastExport() async {
    return getAppPreference<Map<String, dynamic>>('last_export');
  }
}