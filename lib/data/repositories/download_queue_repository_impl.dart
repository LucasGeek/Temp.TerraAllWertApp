import '../../domain/entities/download_queue.dart';
import '../../domain/repositories/download_queue_repository.dart';
import '../datasources/local/download_queue_local_datasource.dart';
import 'package:uuid/uuid.dart';

class DownloadQueueRepositoryImpl implements DownloadQueueRepository {
  final DownloadQueueLocalDataSource _localDataSource;
  final Uuid _uuid = const Uuid();
  
  DownloadQueueRepositoryImpl(this._localDataSource);
  
  @override
  Future<DownloadQueue> create(DownloadQueue download) async {
    try {
      final localDownload = download.copyWith(
        localId: _uuid.v7(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(localDownload);
      return localDownload;
    } catch (e) {
      throw Exception('Failed to create download queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<DownloadQueue> update(DownloadQueue download) async {
    try {
      final updatedDownload = download.copyWith(
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(updatedDownload);
      return updatedDownload;
    } catch (e) {
      throw Exception('Failed to update download queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<void> delete(String localId) async {
    try {
      final download = await _localDataSource.getById(localId);
      if (download == null) return;
      
      final deletedDownload = download.copyWith(
        deletedAt: DateTime.now(),
        isModified: true,
        lastModifiedAt: DateTime.now(),
      );
      
      await _localDataSource.save(deletedDownload);
    } catch (e) {
      throw Exception('Failed to delete download queue item: ${e.toString()}');
    }
  }
  
  @override
  Future<DownloadQueue?> getById(String localId) async {
    try {
      return await _localDataSource.getById(localId);
    } catch (e) {
      throw Exception('Failed to get download queue item by id: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getAll() async {
    try {
      return await _localDataSource.getAll();
    } catch (e) {
      throw Exception('Failed to get all download queue items: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getPending() async {
    try {
      return await _localDataSource.getPending();
    } catch (e) {
      throw Exception('Failed to get pending downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getDownloading() async {
    try {
      return await _localDataSource.getDownloading();
    } catch (e) {
      throw Exception('Failed to get downloading items: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getCompleted() async {
    try {
      return await _localDataSource.getCompleted();
    } catch (e) {
      throw Exception('Failed to get completed downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getFailed() async {
    try {
      return await _localDataSource.getFailed();
    } catch (e) {
      throw Exception('Failed to get failed downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getByResourceType(String resourceType) async {
    try {
      return await _localDataSource.getByResourceType(resourceType);
    } catch (e) {
      throw Exception('Failed to get downloads by resource type: ${e.toString()}');
    }
  }
  
  @override
  Future<DownloadQueue?> getByResourceUrl(String resourceUrl) async {
    try {
      return await _localDataSource.getByResourceUrl(resourceUrl);
    } catch (e) {
      throw Exception('Failed to get download by resource URL: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncFromRemote() async {
    try {
      // Download queue is typically local-only
      // This could fetch server-side download status if needed
      final modifiedDownloads = await _localDataSource.getModified();
      
      for (final download in modifiedDownloads) {
        final syncedDownload = download.copyWith(isModified: false);
        await _localDataSource.save(syncedDownload);
      }
    } catch (e) {
      throw Exception('Failed to sync from remote: ${e.toString()}');
    }
  }
  
  @override
  Future<void> syncToRemote() async {
    try {
      // Download queue is typically local-only
      // This could push download statistics to server
      final modifiedDownloads = await _localDataSource.getModified();
      
      for (final download in modifiedDownloads) {
        try {
          final syncedDownload = download.copyWith(isModified: false);
          await _localDataSource.save(syncedDownload);
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      throw Exception('Failed to sync to remote: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getModified() async {
    try {
      return await _localDataSource.getModified();
    } catch (e) {
      throw Exception('Failed to get modified downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearLocal() async {
    try {
      await _localDataSource.clear();
    } catch (e) {
      throw Exception('Failed to clear local downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteLocal(String localId) async {
    try {
      await _localDataSource.delete(localId);
    } catch (e) {
      throw Exception('Failed to delete local download: ${e.toString()}');
    }
  }
  
  @override
  Future<void> clearCompleted() async {
    try {
      await _localDataSource.clearCompleted();
    } catch (e) {
      throw Exception('Failed to clear completed downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<List<DownloadQueue>> getNextBatch(int limit) async {
    try {
      return await _localDataSource.getNextBatch(limit);
    } catch (e) {
      throw Exception('Failed to get next batch: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateProgress(String localId, double progress) async {
    try {
      final download = await _localDataSource.getById(localId);
      if (download != null) {
        final updatedDownload = download.copyWith(
          progress: progress,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(updatedDownload);
      }
    } catch (e) {
      throw Exception('Failed to update progress: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsCompleted(String localId) async {
    try {
      await _localDataSource.markAsCompleted(localId);
    } catch (e) {
      throw Exception('Failed to mark as completed: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAsFailed(String localId, String error) async {
    try {
      await _localDataSource.markAsFailed(localId, error);
    } catch (e) {
      throw Exception('Failed to mark as failed: ${e.toString()}');
    }
  }
  
  @override
  Future<void> retryFailed() async {
    try {
      await _localDataSource.retryFailed();
    } catch (e) {
      throw Exception('Failed to retry failed downloads: ${e.toString()}');
    }
  }
  
  @override
  Future<void> pauseDownload(String localId) async {
    try {
      final download = await _localDataSource.getById(localId);
      if (download != null) {
        final pausedDownload = download.copyWith(
          status: DownloadStatus.paused,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(pausedDownload);
      }
    } catch (e) {
      throw Exception('Failed to pause download: ${e.toString()}');
    }
  }
  
  @override
  Future<void> resumeDownload(String localId) async {
    try {
      final download = await _localDataSource.getById(localId);
      if (download != null) {
        final resumedDownload = download.copyWith(
          status: DownloadStatus.pending,
          isModified: true,
          lastModifiedAt: DateTime.now(),
        );
        await _localDataSource.save(resumedDownload);
      }
    } catch (e) {
      throw Exception('Failed to resume download: ${e.toString()}');
    }
  }
  
  @override
  Future<int> getTotalQueueSize() async {
    try {
      return await _localDataSource.getTotalQueueSize();
    } catch (e) {
      return 0;
    }
  }
  
  @override
  Future<double> getTotalProgress() async {
    try {
      return await _localDataSource.getTotalProgress();
    } catch (e) {
      return 0.0;
    }
  }
}