import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../platform/platform_service.dart';
import '../logging/app_logger.dart';

/// Universal storage service que funciona em todas as plataformas
/// Web: SharedPreferences + localStorage
/// Mobile (iOS/Android): SecureStorage + SharedPreferences + Files
/// Desktop (macOS/Windows/Linux): SharedPreferences + Files + Keychain/Registry
class UniversalStorageService {
  SharedPreferences? _prefs;
  FlutterSecureStorage? _secureStorage;
  Directory? _documentsDir;
  Directory? _cacheDir;
  Directory? _tempDir;
  
  static const String _keyPrefix = 'terra_allwert_';
  
  /// Inicializa todos os sistemas de storage disponíveis na plataforma
  Future<void> initialize() async {
    try {
      StorageLogger.info('Initializing universal storage for ${PlatformService.platformName}');
      
      // SharedPreferences - disponível em todas as plataformas
      _prefs = await SharedPreferences.getInstance();
      StorageLogger.info('SharedPreferences initialized');
      
      // SecureStorage - disponível apenas em mobile e desktop (não web)
      if (!PlatformService.isWeb) {
        const secureStorageOptions = FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
          lOptions: LinuxOptions(),
          wOptions: WindowsOptions(),
          mOptions: MacOsOptions(
            synchronizable: true,
          ),
        );
        
        _secureStorage = secureStorageOptions;
        StorageLogger.info('Secure storage initialized');
      }
      
      // File system directories - disponível apenas mobile e desktop
      if (PlatformService.supportsFileSystem) {
        _documentsDir = await getApplicationDocumentsDirectory();
        _cacheDir = await getTemporaryDirectory();
        _tempDir = await getTemporaryDirectory();
        
        StorageLogger.info('File system access initialized');
        StorageLogger.debug('Documents: ${_documentsDir?.path}');
        StorageLogger.debug('Cache: ${_cacheDir?.path}');
        StorageLogger.debug('Temp: ${_tempDir?.path}');
      }
      
      StorageLogger.info('Universal storage initialization completed');
      await _logStorageCapabilities();
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to initialize universal storage', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  // ========== STORAGE BÁSICO (String, Int, Bool) ==========
  
  /// Armazena string simples usando SharedPreferences
  Future<void> setString(String key, String value) async {
    try {
      await _ensureInitialized();
      await _prefs!.setString(_keyPrefix + key, value);
      StorageLogger.debug('String stored: $key');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to store string: $key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Obtém string do SharedPreferences
  Future<String?> getString(String key) async {
    try {
      await _ensureInitialized();
      final value = _prefs!.getString(_keyPrefix + key);
      StorageLogger.debug('String retrieved: $key ${value != null ? '(found)' : '(not found)'}');
      return value;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get string: $key', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Armazena int usando SharedPreferences
  Future<void> setInt(String key, int value) async {
    try {
      await _ensureInitialized();
      await _prefs!.setInt(_keyPrefix + key, value);
      StorageLogger.debug('Int stored: $key = $value');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to store int: $key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Obtém int do SharedPreferences
  Future<int?> getInt(String key) async {
    try {
      await _ensureInitialized();
      final value = _prefs!.getInt(_keyPrefix + key);
      StorageLogger.debug('Int retrieved: $key = $value');
      return value;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get int: $key', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Armazena bool usando SharedPreferences
  Future<void> setBool(String key, bool value) async {
    try {
      await _ensureInitialized();
      await _prefs!.setBool(_keyPrefix + key, value);
      StorageLogger.debug('Bool stored: $key = $value');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to store bool: $key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Obtém bool do SharedPreferences
  Future<bool?> getBool(String key) async {
    try {
      await _ensureInitialized();
      final value = _prefs!.getBool(_keyPrefix + key);
      StorageLogger.debug('Bool retrieved: $key = $value');
      return value;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get bool: $key', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  // ========== STORAGE SEGURO (Tokens, Senhas) ==========
  
  /// Armazena dados sensíveis usando SecureStorage (mobile/desktop) ou SharedPreferences (web)
  Future<void> setSecureString(String key, String value) async {
    try {
      await _ensureInitialized();
      
      if (_secureStorage != null) {
        // Mobile/Desktop: usa SecureStorage
        await _secureStorage!.write(key: _keyPrefix + key, value: value);
        StorageLogger.debug('Secure string stored: $key (SecureStorage)');
      } else {
        // Web: fallback para SharedPreferences
        await _prefs!.setString(_keyPrefix + 'secure_' + key, value);
        StorageLogger.debug('Secure string stored: $key (SharedPreferences fallback)');
      }
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to store secure string: $key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Obtém dados sensíveis do SecureStorage
  Future<String?> getSecureString(String key) async {
    try {
      await _ensureInitialized();
      
      String? value;
      if (_secureStorage != null) {
        // Mobile/Desktop: usa SecureStorage
        value = await _secureStorage!.read(key: _keyPrefix + key);
        StorageLogger.debug('Secure string retrieved: $key ${value != null ? '(found)' : '(not found)'} (SecureStorage)');
      } else {
        // Web: fallback para SharedPreferences
        value = _prefs!.getString(_keyPrefix + 'secure_' + key);
        StorageLogger.debug('Secure string retrieved: $key ${value != null ? '(found)' : '(not found)'} (SharedPreferences fallback)');
      }
      
      return value;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get secure string: $key', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Remove dados sensíveis
  Future<void> removeSecureString(String key) async {
    try {
      await _ensureInitialized();
      
      if (_secureStorage != null) {
        await _secureStorage!.delete(key: _keyPrefix + key);
        StorageLogger.debug('Secure string removed: $key (SecureStorage)');
      } else {
        await _prefs!.remove(_keyPrefix + 'secure_' + key);
        StorageLogger.debug('Secure string removed: $key (SharedPreferences fallback)');
      }
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to remove secure string: $key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  // ========== STORAGE JSON (Objetos Complexos) ==========
  
  /// Armazena objeto JSON usando SharedPreferences
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    try {
      await _ensureInitialized();
      final jsonString = jsonEncode(value);
      await _prefs!.setString(_keyPrefix + 'json_' + key, jsonString);
      StorageLogger.debug('JSON stored: $key (${jsonString.length} chars)');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to store JSON: $key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Obtém objeto JSON do SharedPreferences
  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      await _ensureInitialized();
      final jsonString = _prefs!.getString(_keyPrefix + 'json_' + key);
      
      if (jsonString == null) {
        StorageLogger.debug('JSON retrieved: $key (not found)');
        return null;
      }
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      StorageLogger.debug('JSON retrieved: $key (${jsonString.length} chars)');
      return json;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get JSON: $key', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Armazena lista JSON usando SharedPreferences
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    try {
      await _ensureInitialized();
      final jsonString = jsonEncode(value);
      await _prefs!.setString(_keyPrefix + 'json_list_' + key, jsonString);
      StorageLogger.debug('JSON list stored: $key (${value.length} items, ${jsonString.length} chars)');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to store JSON list: $key', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Obtém lista JSON do SharedPreferences
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    try {
      await _ensureInitialized();
      final jsonString = _prefs!.getString(_keyPrefix + 'json_list_' + key);
      
      if (jsonString == null) {
        StorageLogger.debug('JSON list retrieved: $key (not found)');
        return null;
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final result = jsonList.cast<Map<String, dynamic>>();
      StorageLogger.debug('JSON list retrieved: $key (${result.length} items)');
      return result;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get JSON list: $key', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  // ========== FILE STORAGE (Mobile/Desktop apenas) ==========
  
  /// Armazena arquivo nos documents (persistente)
  Future<String?> saveFileToDocuments(String filename, List<int> bytes) async {
    try {
      if (_documentsDir == null) {
        StorageLogger.warning('File storage not available on this platform');
        return null;
      }
      
      final file = File(path.join(_documentsDir!.path, filename));
      await file.writeAsBytes(bytes);
      
      StorageLogger.info('File saved to documents: $filename (${bytes.length} bytes)');
      return file.path;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to save file: $filename', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Carrega arquivo dos documents
  Future<List<int>?> loadFileFromDocuments(String filename) async {
    try {
      if (_documentsDir == null) {
        StorageLogger.warning('File storage not available on this platform');
        return null;
      }
      
      final file = File(path.join(_documentsDir!.path, filename));
      
      if (!await file.exists()) {
        StorageLogger.debug('File not found: $filename');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      StorageLogger.debug('File loaded from documents: $filename (${bytes.length} bytes)');
      return bytes;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to load file: $filename', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Armazena arquivo no cache (temporário)
  Future<String?> saveFileToCache(String filename, List<int> bytes) async {
    try {
      if (_cacheDir == null) {
        StorageLogger.warning('Cache storage not available on this platform');
        return null;
      }
      
      final file = File(path.join(_cacheDir!.path, filename));
      await file.writeAsBytes(bytes);
      
      StorageLogger.debug('File saved to cache: $filename (${bytes.length} bytes)');
      return file.path;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to save file to cache: $filename', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Verifica se arquivo existe
  Future<bool> fileExists(String filename, {bool inDocuments = true}) async {
    try {
      final dir = inDocuments ? _documentsDir : _cacheDir;
      if (dir == null) return false;
      
      final file = File(path.join(dir.path, filename));
      return await file.exists();
    } catch (e) {
      StorageLogger.debug('Error checking file existence: $filename', error: e);
      return false;
    }
  }
  
  /// Remove arquivo
  Future<void> deleteFile(String filename, {bool inDocuments = true}) async {
    try {
      final dir = inDocuments ? _documentsDir : _cacheDir;
      if (dir == null) {
        StorageLogger.warning('File storage not available on this platform');
        return;
      }
      
      final file = File(path.join(dir.path, filename));
      
      if (await file.exists()) {
        await file.delete();
        StorageLogger.debug('File deleted: $filename');
      }
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to delete file: $filename', error: e, stackTrace: stackTrace);
    }
  }
  
  // ========== UTILITY METHODS ==========
  
  /// Remove chave específica
  Future<void> remove(String key) async {
    try {
      await _ensureInitialized();
      await _prefs!.remove(_keyPrefix + key);
      StorageLogger.debug('Key removed: $key');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to remove key: $key', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Verifica se chave existe
  Future<bool> containsKey(String key) async {
    try {
      await _ensureInitialized();
      return _prefs!.containsKey(_keyPrefix + key);
    } catch (e) {
      StorageLogger.debug('Error checking key existence: $key', error: e);
      return false;
    }
  }
  
  /// Lista todas as chaves
  Future<List<String>> getAllKeys() async {
    try {
      await _ensureInitialized();
      final keys = _prefs!.getKeys()
          .where((key) => key.startsWith(_keyPrefix))
          .map((key) => key.substring(_keyPrefix.length))
          .toList();
      
      StorageLogger.debug('Found ${keys.length} keys');
      return keys;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get all keys', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  
  /// Limpa todos os dados do app (CUIDADO!)
  Future<void> clearAll() async {
    try {
      await _ensureInitialized();
      
      // Limpa SharedPreferences
      final keys = await getAllKeys();
      for (final key in keys) {
        await _prefs!.remove(_keyPrefix + key);
      }
      
      // Limpa SecureStorage se disponível
      if (_secureStorage != null) {
        await _secureStorage!.deleteAll();
      }
      
      StorageLogger.warning('All app data cleared (${keys.length} keys)');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to clear all data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Obtém estatísticas de storage
  Future<StorageStats> getStorageStats() async {
    try {
      await _ensureInitialized();
      
      final keys = await getAllKeys();
      final secureKeys = _secureStorage != null ? 
          (await _secureStorage!.readAll()).keys.length : 0;
      
      int documentsFiles = 0;
      int cacheFiles = 0;
      
      if (_documentsDir != null && await _documentsDir!.exists()) {
        documentsFiles = _documentsDir!.listSync().length;
      }
      
      if (_cacheDir != null && await _cacheDir!.exists()) {
        cacheFiles = _cacheDir!.listSync().length;
      }
      
      return StorageStats(
        platform: PlatformService.platformName,
        totalKeys: keys.length,
        secureKeys: secureKeys,
        documentsFiles: documentsFiles,
        cacheFiles: cacheFiles,
        hasSecureStorage: _secureStorage != null,
        hasFileSystem: _documentsDir != null,
        documentsPath: _documentsDir?.path,
        cachePath: _cacheDir?.path,
      );
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get storage stats', error: e, stackTrace: stackTrace);
      
      return StorageStats(
        platform: PlatformService.platformName,
        totalKeys: 0,
        secureKeys: 0,
        documentsFiles: 0,
        cacheFiles: 0,
        hasSecureStorage: false,
        hasFileSystem: false,
      );
    }
  }
  
  // ========== PRIVATE METHODS ==========
  
  /// Garante que o storage foi inicializado
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }
  
  /// Loga capacidades de storage da plataforma
  Future<void> _logStorageCapabilities() async {
    final stats = await getStorageStats();
    
    StorageLogger.info('Storage capabilities for ${stats.platform}:');
    StorageLogger.info('- SharedPreferences: ✓ Available');
    StorageLogger.info('- SecureStorage: ${stats.hasSecureStorage ? '✓' : '✗'} ${stats.hasSecureStorage ? 'Available' : 'Not available'}');
    StorageLogger.info('- File System: ${stats.hasFileSystem ? '✓' : '✗'} ${stats.hasFileSystem ? 'Available' : 'Not available'}');
    
    if (stats.hasFileSystem) {
      StorageLogger.info('  - Documents: ${stats.documentsPath}');
      StorageLogger.info('  - Cache: ${stats.cachePath}');
    }
  }
}

/// Estatísticas do sistema de storage
class StorageStats {
  final String platform;
  final int totalKeys;
  final int secureKeys;
  final int documentsFiles;
  final int cacheFiles;
  final bool hasSecureStorage;
  final bool hasFileSystem;
  final String? documentsPath;
  final String? cachePath;
  
  StorageStats({
    required this.platform,
    required this.totalKeys,
    required this.secureKeys,
    required this.documentsFiles,
    required this.cacheFiles,
    required this.hasSecureStorage,
    required this.hasFileSystem,
    this.documentsPath,
    this.cachePath,
  });
  
  @override
  String toString() {
    return 'StorageStats(platform: $platform, keys: $totalKeys, secureKeys: $secureKeys, '
        'files: ${documentsFiles + cacheFiles}, secure: $hasSecureStorage, fs: $hasFileSystem)';
  }
}

/// Provider para o Universal Storage Service
final universalStorageServiceProvider = Provider<UniversalStorageService>((ref) {
  return UniversalStorageService();
});

/// Provider para inicialização do Universal Storage
final universalStorageServiceInitProvider = FutureProvider<void>((ref) async {
  final universalStorage = ref.watch(universalStorageServiceProvider);
  await universalStorage.initialize();
});

/// Provider para estatísticas do storage
final storageStatsProvider = FutureProvider<StorageStats>((ref) async {
  final universalStorage = ref.watch(universalStorageServiceProvider);
  return await universalStorage.getStorageStats();
});