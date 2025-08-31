import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../platform/platform_service.dart';

abstract class CacheManager {
  Future<void> initialize();
  
  // Cache de dados
  Future<void> cacheData(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getCachedData(String key);
  
  // Cache de imagens
  Future<void> cacheImage(String url, List<int> imageData);
  Future<File?> getCachedImage(String url);
  
  // Cache de queries GraphQL
  Future<void> cacheQuery(String query, Map<String, dynamic> variables, Map<String, dynamic> result);
  Future<Map<String, dynamic>?> getCachedQuery(String query, Map<String, dynamic> variables);
  
  // Limpeza
  Future<void> clearCache();
  Future<void> clearExpiredItems();
  
  // Status
  Future<int> getCacheSize();
  Future<List<String>> getCachedKeys();
}

class CacheManagerImpl implements CacheManager {
  late GetStorage _storage;
  late Directory _cacheDir;
  
  static const String _imagesCacheDir = 'images_cache';
  static const String _dataCacheKey = 'data_cache';
  static const String _queryCacheKey = 'query_cache';
  static const int _maxCacheAgeHours = 24;

  @override
  Future<void> initialize() async {
    await GetStorage.init();
    _storage = GetStorage();
    
    if (PlatformService.supportsFileSystem) {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_imagesCacheDir');
      
      if (!await _cacheDir.exists()) {
        await _cacheDir.create(recursive: true);
      }
    }
  }

  @override
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    final cacheItem = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    final currentCache = _storage.read<Map<String, dynamic>>(_dataCacheKey) ?? {};
    currentCache[key] = cacheItem;
    
    await _storage.write(_dataCacheKey, currentCache);
  }

  @override
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    final currentCache = _storage.read<Map<String, dynamic>>(_dataCacheKey) ?? {};
    final cacheItem = currentCache[key] as Map<String, dynamic>?;
    
    if (cacheItem == null) return null;
    
    final timestamp = cacheItem['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    final maxAge = _maxCacheAgeHours * 60 * 60 * 1000; // em milliseconds
    
    if (age > maxAge) {
      // Item expirou, remove do cache
      currentCache.remove(key);
      await _storage.write(_dataCacheKey, currentCache);
      return null;
    }
    
    return cacheItem['data'] as Map<String, dynamic>?;
  }

  @override
  Future<void> cacheImage(String url, List<int> imageData) async {
    if (!PlatformService.supportsFileSystem) return;
    
    final fileName = _generateImageFileName(url);
    final file = File('${_cacheDir.path}/$fileName');
    
    await file.writeAsBytes(imageData);
    
    // Salva metadados da imagem
    final metadata = {
      'url': url,
      'fileName': fileName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'size': imageData.length,
    };
    
    final currentMetadata = _storage.read<Map<String, dynamic>>('image_metadata') ?? {};
    currentMetadata[url] = metadata;
    await _storage.write('image_metadata', currentMetadata);
  }

  @override
  Future<File?> getCachedImage(String url) async {
    if (!PlatformService.supportsFileSystem) return null;
    
    final currentMetadata = _storage.read<Map<String, dynamic>>('image_metadata') ?? {};
    final metadata = currentMetadata[url] as Map<String, dynamic>?;
    
    if (metadata == null) return null;
    
    final fileName = metadata['fileName'] as String;
    final file = File('${_cacheDir.path}/$fileName');
    
    if (!await file.exists()) {
      // Remove metadados se o arquivo não existir
      currentMetadata.remove(url);
      await _storage.write('image_metadata', currentMetadata);
      return null;
    }
    
    return file;
  }

  @override
  Future<void> cacheQuery(String query, Map<String, dynamic> variables, Map<String, dynamic> result) async {
    final queryKey = _generateQueryKey(query, variables);
    final cacheItem = {
      'query': query,
      'variables': variables,
      'result': result,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    final currentCache = _storage.read<Map<String, dynamic>>(_queryCacheKey) ?? {};
    currentCache[queryKey] = cacheItem;
    
    await _storage.write(_queryCacheKey, currentCache);
  }

  @override
  Future<Map<String, dynamic>?> getCachedQuery(String query, Map<String, dynamic> variables) async {
    final queryKey = _generateQueryKey(query, variables);
    final currentCache = _storage.read<Map<String, dynamic>>(_queryCacheKey) ?? {};
    final cacheItem = currentCache[queryKey] as Map<String, dynamic>?;
    
    if (cacheItem == null) return null;
    
    final timestamp = cacheItem['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    final maxAge = _maxCacheAgeHours * 60 * 60 * 1000;
    
    if (age > maxAge) {
      currentCache.remove(queryKey);
      await _storage.write(_queryCacheKey, currentCache);
      return null;
    }
    
    return cacheItem['result'] as Map<String, dynamic>?;
  }

  @override
  Future<void> clearCache() async {
    await _storage.erase();
    
    if (PlatformService.supportsFileSystem && await _cacheDir.exists()) {
      await _cacheDir.delete(recursive: true);
      await _cacheDir.create(recursive: true);
    }
  }

  @override
  Future<void> clearExpiredItems() async {
    // Limpa dados expirados
    final dataCache = _storage.read<Map<String, dynamic>>(_dataCacheKey) ?? {};
    final queryCache = _storage.read<Map<String, dynamic>>(_queryCacheKey) ?? {};
    final imageMetadata = _storage.read<Map<String, dynamic>>('image_metadata') ?? {};
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxAge = _maxCacheAgeHours * 60 * 60 * 1000;
    
    // Remove dados expirados
    dataCache.removeWhere((key, value) {
      final timestamp = value['timestamp'] as int;
      return (now - timestamp) > maxAge;
    });
    
    queryCache.removeWhere((key, value) {
      final timestamp = value['timestamp'] as int;
      return (now - timestamp) > maxAge;
    });
    
    // Remove imagens expiradas
    final expiredImages = <String>[];
    imageMetadata.forEach((url, metadata) {
      final timestamp = metadata['timestamp'] as int;
      if ((now - timestamp) > maxAge) {
        expiredImages.add(url);
      }
    });
    
    for (final url in expiredImages) {
      final metadata = imageMetadata[url] as Map<String, dynamic>;
      final fileName = metadata['fileName'] as String;
      final file = File('${_cacheDir.path}/$fileName');
      
      if (await file.exists()) {
        await file.delete();
      }
      
      imageMetadata.remove(url);
    }
    
    await _storage.write(_dataCacheKey, dataCache);
    await _storage.write(_queryCacheKey, queryCache);
    await _storage.write('image_metadata', imageMetadata);
  }

  @override
  Future<int> getCacheSize() async {
    int totalSize = 0;
    
    // Tamanho dos dados em storage
    final allData = _storage.getValues();
    final jsonString = json.encode(allData);
    totalSize += jsonString.length;
    
    // Tamanho das imagens
    if (await _cacheDir.exists()) {
      final files = _cacheDir.listSync();
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    }
    
    return totalSize;
  }

  @override
  Future<List<String>> getCachedKeys() async {
    final dataCache = _storage.read<Map<String, dynamic>>(_dataCacheKey) ?? {};
    final queryCache = _storage.read<Map<String, dynamic>>(_queryCacheKey) ?? {};
    final imageMetadata = _storage.read<Map<String, dynamic>>('image_metadata') ?? {};
    
    final keys = <String>[];
    keys.addAll(dataCache.keys.map((k) => 'data:$k'));
    keys.addAll(queryCache.keys.map((k) => 'query:$k'));
    keys.addAll(imageMetadata.keys.map((k) => 'image:$k'));
    
    return keys;
  }

  String _generateImageFileName(String url) {
    final hash = url.hashCode.abs().toString();
    final extension = url.split('.').last.split('?').first;
    return '$hash.$extension';
  }

  String _generateQueryKey(String query, Map<String, dynamic> variables) {
    final combined = '$query${json.encode(variables)}';
    return combined.hashCode.abs().toString();
  }
}

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManagerImpl();
});

final cacheManagerInitProvider = FutureProvider<void>((ref) async {
  final cacheManager = ref.watch(cacheManagerProvider);
  await cacheManager.initialize();
});