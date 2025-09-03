import '../../../infra/storage/cache_adapter.dart';

abstract class CacheManagementLocalDataSource {
  // File Caching
  Future<String> cacheFile({
    required String url,
    required String filename,
    String? category,
    int? expirationHours,
    Map<String, String>? headers,
  });
  
  Future<String?> getCachedFilePath(String url, String filename);
  Future<bool> isCached(String url, String filename);
  Future<void> deleteCachedFile(String cacheKey);
  Future<void> deleteCachedFileByUrl(String url, String filename);
  
  // Image Caching (specialized)
  Future<String> cacheImage({
    required String url,
    String? category,
    int? expirationHours,
    Map<String, String>? headers,
  });
  
  Future<String?> getCachedImagePath(String url);
  
  // Document Caching
  Future<String> cacheDocument({
    required String url,
    required String filename,
    int? expirationHours,
    Map<String, String>? headers,
  });
  
  Future<String?> getCachedDocumentPath(String url, String filename);
  
  // Video Caching
  Future<String> cacheVideo({
    required String url,
    required String filename,
    int? expirationHours,
    Map<String, String>? headers,
  });
  
  Future<String?> getCachedVideoPath(String url, String filename);
  
  // Cache Management
  Future<void> clearExpiredFiles();
  Future<void> clearCacheByCategory(String category);
  Future<void> clearAllCache();
  Future<int> getCacheSizeBytes();
  Future<double> getCacheSizeMB();
  Future<void> cleanupOldFiles();
  Future<Map<String, dynamic>> getCacheStats();
}

class CacheManagementLocalDataSourceImpl implements CacheManagementLocalDataSource {
  final CacheAdapter _cacheAdapter;
  
  CacheManagementLocalDataSourceImpl(this._cacheAdapter);
  
  @override
  Future<String> cacheFile({
    required String url,
    required String filename,
    String? category,
    int? expirationHours,
    Map<String, String>? headers,
  }) async {
    try {
      return await _cacheAdapter.cacheFile(
        url: url,
        filename: filename,
        category: category,
        expirationHours: expirationHours,
        headers: headers,
      );
    } catch (e) {
      throw Exception('Failed to cache file: ${e.toString()}');
    }
  }
  
  @override
  Future<String?> getCachedFilePath(String url, String filename) async {
    try {
      return await _cacheAdapter.getCachedFilePath(url, filename);
    } catch (e) {
      throw Exception('Failed to get cached file path: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> isCached(String url, String filename) async {
    try {
      return await _cacheAdapter.isCached(url, filename);
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<void> deleteCachedFile(String cacheKey) async {
    try {
      await _cacheAdapter.deleteCachedFile(cacheKey);
    } catch (e) {
      throw Exception('Failed to delete cached file: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteCachedFileByUrl(String url, String filename) async {
    try {
      await _cacheAdapter.deleteCachedFileByUrl(url, filename);
    } catch (e) {
      throw Exception('Failed to delete cached file by URL: ${e.toString()}');
    }
  }
  
  @override
  Future<String> cacheImage({
    required String url,
    String? category,
    int? expirationHours,
    Map<String, String>? headers,
  }) async {
    try {
      return await _cacheAdapter.cacheImage(
        url: url,
        category: category,
        expirationHours: expirationHours,
        headers: headers,
      );
    } catch (e) {
      throw Exception('Failed to cache image: ${e.toString()}');
    }
  }
  
  @override
  Future<String?> getCachedImagePath(String url) async {
    try {
      return await _cacheAdapter.getCachedImagePath(url);
    } catch (e) {
      throw Exception('Failed to get cached image path: ${e.toString()}');
    }
  }
  
  @override
  Future<String> cacheDocument({
    required String url,
    required String filename,
    int? expirationHours,
    Map<String, String>? headers,
  }) async {
    try {
      return await _cacheAdapter.cacheDocument(
        url: url,
        filename: filename,
        expirationHours: expirationHours,
        headers: headers,
      );
    } catch (e) {
      throw Exception('Failed to cache document: ${e.toString()}');
    }
  }
  
  @override
  Future<String?> getCachedDocumentPath(String url, String filename) async {
    try {
      return await _cacheAdapter.getCachedDocumentPath(url, filename);
    } catch (e) {
      throw Exception('Failed to get cached document path: ${e.toString()}');
    }
  }
  
  @override
  Future<String> cacheVideo({
    required String url,
    required String filename,
    int? expirationHours,
    Map<String, String>? headers,
  }) async {
    try {
      return await _cacheAdapter.cacheVideo(
        url: url,
        filename: filename,
        expirationHours: expirationHours,
        headers: headers,
      );
    } catch (e) {
      throw Exception('Failed to cache video: ${e.toString()}');
    }
  }
  
  @override
  Future<String?> getCachedVideoPath(String url, String filename) async {
    try {
      return await _cacheAdapter.getCachedVideoPath(url, filename);
    } catch (e) {
      throw Exception('Failed to get cached video path: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearExpiredFiles() async {
    try {
      await _cacheAdapter.clearExpiredFiles();
    } catch (e) {
      throw Exception('Failed to clear expired files: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearCacheByCategory(String category) async {
    try {
      await _cacheAdapter.clearCacheByCategory(category);
    } catch (e) {
      throw Exception('Failed to clear cache by category: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearAllCache() async {
    try {
      await _cacheAdapter.clearAllCache();
    } catch (e) {
      throw Exception('Failed to clear all cache: ${e.toString()}');
    }
  }
  
  @override
  Future<int> getCacheSizeBytes() async {
    try {
      return await _cacheAdapter.getCacheSizeBytes();
    } catch (e) {
      return 0;
    }
  }
  
  @override
  Future<double> getCacheSizeMB() async {
    try {
      return await _cacheAdapter.getCacheSizeMB();
    } catch (e) {
      return 0.0;
    }
  }
  
  @override
  Future<void> cleanupOldFiles() async {
    try {
      await _cacheAdapter.cleanupOldFiles();
    } catch (e) {
      throw Exception('Failed to cleanup old files: ${e.toString()}');
    }
  }
  
  @override
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return await _cacheAdapter.getCacheStats();
    } catch (e) {
      return {
        'totalFiles': 0,
        'totalSizeMB': 0.0,
        'expiredFiles': 0,
        'categoryCounts': <String, int>{},
        'maxSizeMB': 500,
      };
    }
  }
}