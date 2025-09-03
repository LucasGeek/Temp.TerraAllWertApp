import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class CacheAdapter {
  static const String _cacheDir = 'terra_allwert_cache';
  static const String _metadataDir = 'metadata';
  static const int _maxCacheSizeMB = 500; // 500MB max cache
  static const int _defaultExpirationHours = 24;
  
  Directory? _cacheDirectory;
  Directory? _metadataDirectory;
  
  CacheAdapter._();
  
  static CacheAdapter? _instance;
  
  static Future<CacheAdapter> getInstance() async {
    if (_instance == null) {
      _instance = CacheAdapter._();
      await _instance!._initializeDirectories();
    }
    return _instance!;
  }
  
  Future<void> _initializeDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory(path.join(appDir.path, _cacheDir));
    _metadataDirectory = Directory(path.join(appDir.path, _cacheDir, _metadataDir));
    
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
    
    if (!await _metadataDirectory!.exists()) {
      await _metadataDirectory!.create(recursive: true);
    }
  }
  
  // ===== File Caching Operations =====
  
  Future<String> cacheFile({
    required String url,
    required String filename,
    String? category,
    int? expirationHours,
    Map<String, String>? headers,
  }) async {
    final cacheKey = _generateCacheKey(url, filename);
    final categoryDir = category != null 
        ? Directory(path.join(_cacheDirectory!.path, category))
        : _cacheDirectory!;
    
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }
    
    final filePath = path.join(categoryDir.path, '$cacheKey-$filename');
    final file = File(filePath);
    
    try {
      // Download file
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        
        // Save metadata
        await _saveCacheMetadata(
          cacheKey: cacheKey,
          originalUrl: url,
          filePath: filePath,
          filename: filename,
          category: category,
          fileSize: response.bodyBytes.length,
          mimeType: response.headers['content-type'],
          expirationHours: expirationHours ?? _defaultExpirationHours,
        );
        
        return filePath;
      } else {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (await file.exists()) {
        await file.delete();
      }
      throw Exception('Failed to cache file: ${e.toString()}');
    }
  }
  
  Future<String?> getCachedFilePath(String url, String filename) async {
    final cacheKey = _generateCacheKey(url, filename);
    final metadata = await _getCacheMetadata(cacheKey);
    
    if (metadata == null) return null;
    
    final file = File(metadata['filePath']);
    if (!await file.exists()) {
      await _deleteCacheMetadata(cacheKey);
      return null;
    }
    
    // Check expiration
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(metadata['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      await deleteCachedFile(cacheKey);
      return null;
    }
    
    return metadata['filePath'];
  }
  
  Future<bool> isCached(String url, String filename) async {
    final cachedPath = await getCachedFilePath(url, filename);
    return cachedPath != null;
  }
  
  Future<void> deleteCachedFile(String cacheKey) async {
    final metadata = await _getCacheMetadata(cacheKey);
    if (metadata != null) {
      final file = File(metadata['filePath']);
      if (await file.exists()) {
        await file.delete();
      }
      await _deleteCacheMetadata(cacheKey);
    }
  }
  
  Future<void> deleteCachedFileByUrl(String url, String filename) async {
    final cacheKey = _generateCacheKey(url, filename);
    await deleteCachedFile(cacheKey);
  }
  
  // ===== Image Caching (specialized for images) =====
  
  Future<String> cacheImage({
    required String url,
    String? category,
    int? expirationHours,
    Map<String, String>? headers,
  }) async {
    final filename = _extractFilenameFromUrl(url) ?? 'image_${DateTime.now().millisecondsSinceEpoch}';
    return await cacheFile(
      url: url,
      filename: filename,
      category: category ?? 'images',
      expirationHours: expirationHours,
      headers: headers,
    );
  }
  
  Future<String?> getCachedImagePath(String url) async {
    final filename = _extractFilenameFromUrl(url) ?? 'image_${_generateCacheKey(url, '')}';
    return await getCachedFilePath(url, filename);
  }
  
  // ===== Document Caching =====
  
  Future<String> cacheDocument({
    required String url,
    required String filename,
    int? expirationHours,
    Map<String, String>? headers,
  }) async {
    return await cacheFile(
      url: url,
      filename: filename,
      category: 'documents',
      expirationHours: expirationHours,
      headers: headers,
    );
  }
  
  Future<String?> getCachedDocumentPath(String url, String filename) async {
    return await getCachedFilePath(url, filename);
  }
  
  // ===== Video Caching =====
  
  Future<String> cacheVideo({
    required String url,
    required String filename,
    int? expirationHours,
    Map<String, String>? headers,
  }) async {
    return await cacheFile(
      url: url,
      filename: filename,
      category: 'videos',
      expirationHours: expirationHours ?? 168, // 7 days for videos
      headers: headers,
    );
  }
  
  Future<String?> getCachedVideoPath(String url, String filename) async {
    return await getCachedFilePath(url, filename);
  }
  
  // ===== Cache Management =====
  
  Future<void> clearExpiredFiles() async {
    final allMetadata = await _getAllCacheMetadata();
    final now = DateTime.now();
    
    for (final metadata in allMetadata) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(metadata['expiresAt']);
      if (now.isAfter(expiresAt)) {
        final file = File(metadata['filePath']);
        if (await file.exists()) {
          await file.delete();
        }
        await _deleteCacheMetadata(metadata['cacheKey']);
      }
    }
  }
  
  Future<void> clearCacheByCategory(String category) async {
    final categoryDir = Directory(path.join(_cacheDirectory!.path, category));
    if (await categoryDir.exists()) {
      await categoryDir.delete(recursive: true);
    }
    
    // Remove metadata for this category
    final allMetadata = await _getAllCacheMetadata();
    for (final metadata in allMetadata) {
      if (metadata['category'] == category) {
        await _deleteCacheMetadata(metadata['cacheKey']);
      }
    }
  }
  
  Future<void> clearAllCache() async {
    if (await _cacheDirectory!.exists()) {
      await _cacheDirectory!.delete(recursive: true);
      await _initializeDirectories();
    }
  }
  
  Future<int> getCacheSizeBytes() async {
    int totalSize = 0;
    await for (final entity in _cacheDirectory!.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        totalSize += stat.size;
      }
    }
    return totalSize;
  }
  
  Future<double> getCacheSizeMB() async {
    final bytes = await getCacheSizeBytes();
    return bytes / (1024 * 1024);
  }
  
  Future<void> cleanupOldFiles() async {
    final currentSizeMB = await getCacheSizeMB();
    if (currentSizeMB > _maxCacheSizeMB) {
      final allMetadata = await _getAllCacheMetadata();
      // Sort by creation date (oldest first)
      allMetadata.sort((a, b) => a['createdAt'].compareTo(b['createdAt']));
      
      // Delete oldest files until under limit
      for (final metadata in allMetadata) {
        final file = File(metadata['filePath']);
        if (await file.exists()) {
          await file.delete();
        }
        await _deleteCacheMetadata(metadata['cacheKey']);
        
        final newSizeMB = await getCacheSizeMB();
        if (newSizeMB <= _maxCacheSizeMB * 0.8) { // Keep 20% buffer
          break;
        }
      }
    }
  }
  
  Future<Map<String, dynamic>> getCacheStats() async {
    final allMetadata = await _getAllCacheMetadata();
    final sizeMB = await getCacheSizeMB();
    final now = DateTime.now();
    
    int expiredCount = 0;
    Map<String, int> categoryCount = {};
    
    for (final metadata in allMetadata) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(metadata['expiresAt']);
      if (now.isAfter(expiresAt)) {
        expiredCount++;
      }
      
      final category = metadata['category'] ?? 'uncategorized';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    return {
      'totalFiles': allMetadata.length,
      'totalSizeMB': sizeMB,
      'expiredFiles': expiredCount,
      'categoryCounts': categoryCount,
      'maxSizeMB': _maxCacheSizeMB,
    };
  }
  
  // ===== Private Helper Methods =====
  
  String _generateCacheKey(String url, String filename) {
    final bytes = utf8.encode('$url-$filename');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  String? _extractFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }
  
  Future<void> _saveCacheMetadata({
    required String cacheKey,
    required String originalUrl,
    required String filePath,
    required String filename,
    String? category,
    required int fileSize,
    String? mimeType,
    required int expirationHours,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: expirationHours));
    
    final metadata = {
      'cacheKey': cacheKey,
      'originalUrl': originalUrl,
      'filePath': filePath,
      'filename': filename,
      'category': category,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'createdAt': now.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
    
    final metadataFile = File(path.join(_metadataDirectory!.path, '$cacheKey.json'));
    await metadataFile.writeAsString(jsonEncode(metadata));
  }
  
  Future<Map<String, dynamic>?> _getCacheMetadata(String cacheKey) async {
    final metadataFile = File(path.join(_metadataDirectory!.path, '$cacheKey.json'));
    if (!await metadataFile.exists()) return null;
    
    try {
      final jsonString = await metadataFile.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
  
  Future<void> _deleteCacheMetadata(String cacheKey) async {
    final metadataFile = File(path.join(_metadataDirectory!.path, '$cacheKey.json'));
    if (await metadataFile.exists()) {
      await metadataFile.delete();
    }
  }
  
  Future<List<Map<String, dynamic>>> _getAllCacheMetadata() async {
    final List<Map<String, dynamic>> allMetadata = [];
    
    await for (final entity in _metadataDirectory!.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final jsonString = await entity.readAsString();
          final metadata = jsonDecode(jsonString) as Map<String, dynamic>;
          allMetadata.add(metadata);
        } catch (_) {
          // Ignore corrupted metadata files
        }
      }
    }
    
    return allMetadata;
  }
}