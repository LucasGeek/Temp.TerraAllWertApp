import '../../../domain/entities/download_queue.dart';
import '../../../infra/storage/local_storage_adapter.dart';

abstract class DownloadQueueLocalDataSource {
  Future<List<DownloadQueue>> getAll();
  Future<DownloadQueue?> getById(String id);
  Future<List<DownloadQueue>> getPending();
  Future<List<DownloadQueue>> getDownloading();
  Future<List<DownloadQueue>> getCompleted();
  Future<List<DownloadQueue>> getFailed();
  Future<void> save(DownloadQueue download);
  Future<void> saveAll(List<DownloadQueue> downloads);
  Future<void> delete(String id);
  Future<void> clear();
  Future<List<DownloadQueue>> getModified();
  Future<void> updateSyncStatus(String localId, String remoteId);
  Future<List<DownloadQueue>> getNextBatch(int limit);
  Future<List<DownloadQueue>> getByResourceType(String resourceType);
  Future<DownloadQueue?> getByResourceUrl(String resourceUrl);
  Future<void> clearCompleted();
  Future<void> markAsCompleted(String id);
  Future<void> markAsFailed(String id, String error);
  Future<void> retryFailed();
  Future<int> getTotalQueueSize();
  Future<double> getTotalProgress();
}

class DownloadQueueLocalDataSourceImpl implements DownloadQueueLocalDataSource {
  final LocalStorageAdapter _storage;
  final String _key = 'download_queue';
  
  DownloadQueueLocalDataSourceImpl(this._storage);
  
  @override
  Future<List<DownloadQueue>> getAll() async {
    try {
      final data = _storage.getJsonList(_key);
      return data?.map((json) => DownloadQueue.fromJson(json)).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<DownloadQueue?> getById(String id) async {
    try {
      final downloads = await getAll();
      return downloads.where((download) => download.localId == id || download.remoteId == id).firstOrNull;
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<DownloadQueue>> getPending() async {
    try {
      final downloads = await getAll();
      return downloads.where((download) => download.status == DownloadStatus.pending).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<DownloadQueue>> getDownloading() async {
    try {
      final downloads = await getAll();
      return downloads.where((download) => download.status == DownloadStatus.downloading).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<DownloadQueue>> getCompleted() async {
    try {
      final downloads = await getAll();
      return downloads.where((download) => download.status == DownloadStatus.completed).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<List<DownloadQueue>> getFailed() async {
    try {
      final downloads = await getAll();
      return downloads.where((download) => download.status == DownloadStatus.failed).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> save(DownloadQueue download) async {
    try {
      final downloads = await getAll();
      final index = downloads.indexWhere((d) => d.localId == download.localId);
      
      if (index >= 0) {
        downloads[index] = download;
      } else {
        downloads.add(download);
      }
      
      final jsonList = downloads.map((download) => download.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save download queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> saveAll(List<DownloadQueue> downloads) async {
    try {
      final jsonList = downloads.map((download) => download.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to save download queue items: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      final downloads = await getAll();
      downloads.removeWhere((download) => download.localId == id || download.remoteId == id);
      
      final jsonList = downloads.map((download) => download.toJson()).toList();
      await _storage.setJsonList(_key, jsonList);
    } catch (e) {
      throw Exception('Failed to delete download queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      await _storage.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear download queue: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getModified() async {
    try {
      // DownloadQueue não tem campo isModified, retornar lista vazia
      return [];
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> updateSyncStatus(String localId, String remoteId) async {
    try {
      final download = await getById(localId);
      if (download != null) {
        // DownloadQueue não tem esses campos, apenas salvar sem modificar
        final updatedDownload = download;
        await save(updatedDownload);
      }
    } catch (e) {
      throw Exception('Failed to update sync status: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getNextBatch(int limit) async {
    try {
      final pending = await getPending();
      pending.sort((a, b) => a.priority.compareTo(b.priority)); // Higher priority first
      return pending.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<DownloadQueue>> getByResourceType(String resourceType) async {
    try {
      final downloads = await getAll();
      return downloads.where((download) => download.resourceType == resourceType).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<DownloadQueue?> getByResourceUrl(String resourceUrl) async {
    try {
      final downloads = await getAll();
      return downloads.where((download) => download.resourceUrl == resourceUrl).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearCompleted() async {
    try {
      final downloads = await getAll();
      final remaining = downloads.where((download) => download.status != DownloadStatus.completed).toList();
      await _storage.setJsonList(_key, remaining.map((d) => d.toJson()).toList());
    } catch (e) {
      throw Exception('Failed to clear completed downloads: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsCompleted(String id) async {
    try {
      final download = await getById(id);
      if (download != null) {
        final completed = download.copyWith(
          status: DownloadStatus.completed,
          completedAt: DateTime.now(),
        );
        await save(completed);
      }
    } catch (e) {
      throw Exception('Failed to mark as completed: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsFailed(String id, String error) async {
    try {
      final download = await getById(id);
      if (download != null) {
        final failed = download.copyWith(
          status: DownloadStatus.failed,
          errorMessage: error,
        );
        await save(failed);
      }
    } catch (e) {
      throw Exception('Failed to mark as failed: ${e.toString()}');
    }
  }

  @override
  Future<void> retryFailed() async {
    try {
      final failed = await getFailed();
      for (final download in failed) {
        final retried = download.copyWith(
          status: DownloadStatus.pending,
          retryCount: download.retryCount + 1,
          errorMessage: null,
        );
        await save(retried);
      }
    } catch (e) {
      throw Exception('Failed to retry failed downloads: ${e.toString()}');
    }
  }

  @override
  Future<int> getTotalQueueSize() async {
    try {
      final downloads = await getAll();
      return downloads.fold<int>(0, (sum, download) => sum + (download.fileSizeBytes ?? 0));
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<double> getTotalProgress() async {
    try {
      final downloads = await getAll();
      if (downloads.isEmpty) return 0.0;
      
      final totalProgress = downloads.fold<double>(0.0, (sum, download) => sum + download.progress);
      return totalProgress / downloads.length;
    } catch (e) {
      return 0.0;
    }
  }
}