import '../../domain/entities/cached_file.dart';
import '../../domain/repositories/cached_file_repository.dart';
import '../datasources/local/cached_file_local_datasource.dart';
import 'package:uuid/uuid.dart';

class CachedFileRepositoryImpl implements CachedFileRepository {
  final CachedFileLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();
  
  CachedFileRepositoryImpl(this._localDataSource);
  
  @override
  Future<CachedFile> create(CachedFile file) async {
    try {
      final localFile = file.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localFile);
      return localFile;
    } catch (e) {
      throw Exception('Failed to create cached file: ${e.toString()}');
    }
  }
  
  @override
  Future<CachedFile> update(CachedFile file) async {
    try {
      final updatedFile = file.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(updatedFile);
      return updatedFile;
    } catch (e) {
      throw Exception('Failed to update cached file: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete cached file: ${e.toString()}');
    }
  }
  
  @override
  Future<CachedFile?> getById(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get cached file by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CachedFile>> getAll() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get all cached files: ${e.toString()}');
    }
  }
  
  @override
  Future<CachedFile?> getByUrl(String originalUrl) async {
    try {
      return await _localDataSource.getByUrl(originalUrl);
    } catch (e) {
      throw Exception('Failed to get cached file by URL: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CachedFile>> getDownloaded() async {
    try {
      return await _localDataSource.getDownloaded();
    } catch (e) {
      throw Exception('Failed to get downloaded files: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CachedFile>> getPending() async {
    try {
      return await _localDataSource.getPending();
    } catch (e) {
      throw Exception('Failed to get pending files: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CachedFile>> getFailed() async {
    try {
      final files = await _localDataSource.getAll();
      return files.where((file) => !file.isDownloaded && file.downloadedAt == null).toList();
    } catch (e) {
      throw Exception('Failed to get failed files: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CachedFile>> getByType(String fileType) async {
    try {
      final files = await _localDataSource.getAll();
      return files.where((file) => file.fileType == fileType).toList();
    } catch (e) {
      throw Exception('Failed to get files by type: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateDownloadStatus(String localId, bool isDownloaded, String? localPath) async {
    try {
      await _localDataSource.updateDownloadStatus(localId, isDownloaded, localPath);
    } catch (e) {
      throw Exception('Failed to update download status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateProgress(String localId, double progress) async {
    try {
      final file = await _localDataSource.getById(localId);
      if (file != null) {
        final updatedFile = file.copyWith(
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(updatedFile);
      }
    } catch (e) {
      throw Exception('Failed to update progress: ${e.toString()}');
    }
  }
  
  @override
  Future<int> getTotalCacheSize() async {
    try {
      final files = await _localDataSource.getDownloaded();
      return files.fold<int>(0, (sum, file) => sum + file.fileSizeBytes);
    } catch (e) {
      throw Exception('Failed to get total cache size: ${e.toString()}');
    }
  }
  
  @override
  Future<void> cleanupCache(int maxSizeBytes) async {
    try {
      final totalSize = await getTotalCacheSize();
      if (totalSize <= maxSizeBytes) return;
      
      final files = await _localDataSource.getDownloaded();
      files.sort((a, b) => (a.downloadedAt ?? DateTime.now()).compareTo(b.downloadedAt ?? DateTime.now()));
      
      int currentSize = totalSize;
      for (final file in files) {
        if (currentSize <= maxSizeBytes) break;
        
        await _localDataSource.delete(file.localId);
        currentSize -= file.fileSizeBytes;
      }
    } catch (e) {
      throw Exception('Failed to cleanup cache: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearExpired() async {
    try {
      final files = await _localDataSource.getAll();
      final now = DateTime.now();
      const expiryDuration = Duration(days: 30); // Files expire after 30 days
      
      for (final file in files) {
        if (file.downloadedAt != null && 
            now.difference(file.downloadedAt!).compareTo(expiryDuration) > 0) {
          await _localDataSource.delete(file.localId);
        }
      }
    } catch (e) {
      throw Exception('Failed to clear expired files: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncFromRemote() async {
    // CachedFile is typically local-only, no remote sync needed
    return;
  }
  
  @override
  Future<void> syncToRemote() async {
    // CachedFile is typically local-only, no remote sync needed
    return;
  }
  
  @override
  Future<List<CachedFile>> getModified() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get modified cached files: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local cached files: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete local cached file: ${e.toString()}');
    }
  }
}