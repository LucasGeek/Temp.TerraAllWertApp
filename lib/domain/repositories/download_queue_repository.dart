import '../entities/download_queue.dart';

abstract class DownloadQueueRepository {
  // Basic CRUD operations
  Future<DownloadQueue> create(DownloadQueue download);
  Future<DownloadQueue> update(DownloadQueue download);
  Future<void> delete(String localId);
  Future<DownloadQueue?> getById(String localId);
  Future<List<DownloadQueue>> getAll();
  
  // Business-specific queries
  Future<List<DownloadQueue>> getPending();
  Future<List<DownloadQueue>> getDownloading();
  Future<List<DownloadQueue>> getCompleted();
  Future<List<DownloadQueue>> getFailed();
  Future<List<DownloadQueue>> getByResourceType(String resourceType);
  Future<DownloadQueue?> getByResourceUrl(String resourceUrl);
  
  // Sync operations
  Future<void> syncFromRemote();
  Future<void> syncToRemote();
  Future<List<DownloadQueue>> getModified();
  
  // Local operations
  Future<void> clearLocal();
  Future<void> deleteLocal(String localId);
  Future<void> clearCompleted();
  
  // Download queue management
  Future<List<DownloadQueue>> getNextBatch(int limit);
  Future<void> updateProgress(String localId, double progress);
  Future<void> markAsCompleted(String localId);
  Future<void> markAsFailed(String localId, String error);
  Future<void> retryFailed();
  Future<void> pauseDownload(String localId);
  Future<void> resumeDownload(String localId);
  Future<int> getTotalQueueSize();
  Future<double> getTotalProgress();
}