import '../../../domain/entities/cached_file.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class CachedFileLocalDataSource {
  Future<List<CachedFile>> getAll();
  Future<CachedFile?> getById(String id);
  Future<CachedFile?> getByUrl(String url);
  Future<void> save(CachedFile file);
  Future<void> saveAll(List<CachedFile> files);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<CachedFile>> getDownloaded();
  Future<List<CachedFile>> getPending();
  Future<void> updateDownloadStatus(String localId, bool isDownloaded, String? localPath);
}

class CachedFileLocalDataSourceImpl implements CachedFileLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'cached_files';
  
  CachedFileLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<CachedFile>> getAll() async {
    try {
      final data = _storage.getList(_key);
      return data?.map((json) => CachedFile.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<CachedFile?> getById(String id) async {
    try {
      final files = await getAll();
      return files.where((file) => file.localId == id || file.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<CachedFile?> getByUrl(String url) async {
    try {
      final files = await getAll();
      return files.where((file) => file.remoteUrl == url).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> save(CachedFile file) async {
    try {
      final files = await getAll();
      final index = files.indexWhere((f) => f.localId == file.localId);
      
      if (index >= 0) {
        files[index] = file;
      } else {
        files.add(file);
      }
      
      final jsonList = files.map((file) => file.toJson()).toList();
      await _storage.setList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save cached file: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<CachedFile> files) async {
    try {
      final jsonList = files.map((file) => file.toJson()).toList();
      await _storage.setList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save cached files: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final files = await getAll();
      files.removeWhere((file) => file.localId == id || file.remoteId == id);
      
      final jsonList = files.map((file) => file.toJson()).toList();
      await _storage.setList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete cached file: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear cached files: ${e.toString()}');
    }
  }
  
  @override
  Future<List<CachedFile>> getDownloaded() async {
    try {
      final files = await getAll();
      return files.where((file) => file.cacheStatus == CacheStatus.cached).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<CachedFile>> getPending() async {
    try {
      final files = await getAll();
      return files.where((file) => file.cacheStatus == CacheStatus.pending).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateDownloadStatus(String localId, bool isDownloaded, String? localPath) async {
    try {
      final file = await getById(localId);
      if (file != null) {
        final updatedFile = file.copyWith(
          cacheStatus: isDownloaded ? CacheStatus.cached : CacheStatus.pending,
          cachePath: localPath,
          lastAccessedAt: DateTime.now(),
        );
        await save(updatedFile);
      }
    } catch (e) {
      throw Exception('Failed to update download status: ${e.toString()}');
    }
  }
}