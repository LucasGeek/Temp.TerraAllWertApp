import '../entities/cached_file.dart';

abstract class CachedFileRepository {
  // Basic CRUD operations
  Future<CachedFile> create(CachedFile file);
  Future<CachedFile> update(CachedFile file);
  Future<void> delete(String localId);
  Future<CachedFile?> getById(String localId);
  Future<List<CachedFile>> getAll();
  
  // Business-specific queries
  Future<CachedFile?> getByUrl(String originalUrl);
  Future<List<CachedFile>> getDownloaded();
  Future<List<CachedFile>> getPending();
  Future<List<CachedFile>> getFailed();
  Future<List<CachedFile>> getByType(String fileType);
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<CachedFile>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  Future<void> clearExpired();
  
  // Download management
  Future<void> updateDownloadStatus(String localId, bool isDownloaded, String? localPath);
  Future<void> updateProgress(String localId, double progress);
  Future<int> getTotalCacheSize();
  Future<void> cleanupCache(int maxSizeBytes);
}