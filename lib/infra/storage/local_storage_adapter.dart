import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageAdapter {
  late final GetStorage _getStorage;
  late final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _sharedPrefs;
  
  LocalStorageAdapter._();
  
  static LocalStorageAdapter? _instance;
  
  static Future<LocalStorageAdapter> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageAdapter._();
      await _instance!._initialize();
    }
    return _instance!;
  }
  
  Future<void> _initialize() async {
    await GetStorage.init('terra_allwert');
    _getStorage = GetStorage('terra_allwert');
    _secureStorage = const FlutterSecureStorage();
    _sharedPrefs = await SharedPreferences.getInstance();
  }
  
  // ===== GetStorage Operations (for JSON data) =====
  
  Future<void> saveJson(String key, Map<String, dynamic> data) async {
    await _getStorage.write(key, data);
  }
  
  Map<String, dynamic>? getJson(String key) {
    final data = _getStorage.read(key);
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
  
  Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    await _getStorage.write(key, list);
  }
  
  List<Map<String, dynamic>>? getList(String key) {
    final data = _getStorage.read(key);
    if (data == null) return null;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return null;
  }

  // Alias methods for compatibility
  Future<void> saveJsonMap(String key, Map<String, dynamic> data) async {
    await saveJson(key, data);
  }
  
  Map<String, dynamic>? getJsonMap(String key) {
    return getJson(key);
  }
  
  Future<void> setJsonList(String key, List<Map<String, dynamic>> list) async {
    await saveList(key, list);
  }
  
  List<Map<String, dynamic>>? getJsonList(String key) {
    return getList(key);
  }
  
  Future<void> setList(String key, List<Map<String, dynamic>> list) async {
    await saveList(key, list);
  }
  
  Future<void> remove(String key) async {
    await _getStorage.remove(key);
  }
  
  Future<void> clearAll() async {
    await _getStorage.erase();
  }
  
  // ===== Secure Storage Operations (for sensitive data) =====
  
  Future<void> saveSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  Future<String?> getSecure(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  Future<void> removeSecure(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }
  
  // ===== SharedPreferences Operations (for simple preferences) =====
  
  Future<void> setBool(String key, bool value) async {
    await _sharedPrefs.setBool(key, value);
  }
  
  bool? getBool(String key) {
    return _sharedPrefs.getBool(key);
  }
  
  Future<void> setString(String key, String value) async {
    await _sharedPrefs.setString(key, value);
  }
  
  String? getString(String key) {
    return _sharedPrefs.getString(key);
  }
  
  Future<void> setInt(String key, int value) async {
    await _sharedPrefs.setInt(key, value);
  }
  
  int? getInt(String key) {
    return _sharedPrefs.getInt(key);
  }
  
  Future<void> setDouble(String key, double value) async {
    await _sharedPrefs.setDouble(key, value);
  }
  
  double? getDouble(String key) {
    return _sharedPrefs.getDouble(key);
  }
  
  Future<void> setStringList(String key, List<String> value) async {
    await _sharedPrefs.setStringList(key, value);
  }
  
  List<String>? getStringList(String key) {
    return _sharedPrefs.getStringList(key);
  }
  
  Future<void> removePreference(String key) async {
    await _sharedPrefs.remove(key);
  }
  
  // ===== Storage Keys =====
  
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyCurrentUser = 'current_user';
  static const String keyEnterprises = 'enterprises';
  static const String keyMenus = 'menus';
  static const String keyTowers = 'towers';
  static const String keyFloors = 'floors';
  static const String keySuites = 'suites';
  static const String keySyncQueue = 'sync_queue';
  static const String keyLastSync = 'last_sync';
  static const String keyOfflineMode = 'offline_mode';
  static const String keyAutoSync = 'auto_sync';
  static const String keyCacheVersion = 'cache_version';
}