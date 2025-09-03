import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/repositories/download_queue_repository.dart';
import '../../domain/repositories/cached_file_repository.dart';
import '../../domain/entities/download_queue.dart';
import '../../domain/entities/cached_file.dart';
import '../http/rest_client.dart';

class DownloadService {
  final DownloadQueueRepository _queueRepository;
  final CachedFileRepository _fileRepository;
  final RestClient _client;
  
  bool _isDownloading = false;
  
  DownloadService(
    this._queueRepository,
    this._fileRepository,
    this._client,
  );
  
  /// Starts the download process
  Future<void> startDownloads() async {
    if (_isDownloading) return;
    
    _isDownloading = true;
    
    try {
      while (_isDownloading) {
        final nextBatch = await _queueRepository.getNextBatch(3); // Process 3 concurrent downloads
        
        if (nextBatch.isEmpty) {
          await Future.delayed(const Duration(seconds: 5)); // Wait before checking again
          continue;
        }
        
        // Process downloads concurrently
        await Future.wait(
          nextBatch.map((download) => _processDownload(download)),
        );
      }
    } catch (e) {
      throw Exception('Download service error: ${e.toString()}');
    } finally {
      _isDownloading = false;
    }
  }
  
  /// Stops the download process
  void stopDownloads() {
    _isDownloading = false;
  }
  
  /// Processes a single download
  Future<void> _processDownload(DownloadQueue download) async {
    try {
      // Update status to downloading
      final downloadingItem = download.copyWith(
        status: DownloadStatus.downloading,
        startedAt: DateTime.now(),
      );
      await _queueRepository.update(downloadingItem);
      
      // Download file
      final localPath = await _downloadFile(download.resourceUrl);
      
      // Create cached file entry
      final cachedFile = CachedFile(
        localId: download.resourceLocalId,
        remoteUrl: download.resourceUrl,
        cachePath: localPath,
        cacheStatus: CacheStatus.cached,
        fileSizeBytes: download.fileSizeBytes ?? 0,
        fileType: 'download',
        mimeType: 'application/octet-stream',
        originalName: 'downloaded_file',
        createdAt: DateTime.now(),
      );
      
      await _fileRepository.create(cachedFile);
      
      // Mark download as completed
      await _queueRepository.markAsCompleted(download.localId);
      
    } catch (e) {
      // Mark download as failed
      await _queueRepository.markAsFailed(download.localId, e.toString());
      
      // Increment retry count
      final updatedDownload = download.copyWith(
        retryCount: download.retryCount + 1,
      );
      
      // If max retries reached, keep as failed, otherwise reset to pending
      if (updatedDownload.retryCount < updatedDownload.maxRetries) {
        final retryDownload = updatedDownload.copyWith(
          status: DownloadStatus.pending,
        );
        await _queueRepository.update(retryDownload);
      } else {
        await _queueRepository.update(updatedDownload);
      }
    }
  }
  
  /// Downloads a file and returns the local path
  Future<String> _downloadFile(String url) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.last;
      
      // Create local directory if needed
      final directory = Directory('/tmp/terra_allwert_cache');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final localPath = '${directory.path}/$filename';
      
      // Download file using HTTP client
      final response = await _client.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      
      // Save to local file
      final file = File(localPath);
      await file.writeAsBytes(response.data);
      
      return localPath;
    } catch (e) {
      throw Exception('Failed to download file: ${e.toString()}');
    }
  }
  
  /// Queues a file for download
  Future<void> queueDownload(String resourceUrl, String resourceType, {int priority = 5}) async {
    try {
      // Check if already queued or cached
      final existingQueue = await _queueRepository.getByResourceUrl(resourceUrl);
      if (existingQueue != null) {
        return; // Already queued
      }
      
      final existingCache = await _fileRepository.getByUrl(resourceUrl);
      if (existingCache != null && existingCache.isDownloaded) {
        return; // Already downloaded
      }
      
      // Create download queue item
      final download = DownloadQueue(
        localId: '', // Will be set by repository
        resourceType: resourceType,
        resourceLocalId: '', // This would be set based on context
        resourceUrl: resourceUrl,
        priority: priority,
        status: DownloadStatus.pending,
        createdAt: DateTime.now(),
      );
      
      await _queueRepository.create(download);
    } catch (e) {
      throw Exception('Failed to queue download: ${e.toString()}');
    }
  }
  
  /// Gets download progress summary
  Future<DownloadProgress> getProgress() async {
    try {
      final totalSize = await _queueRepository.getTotalQueueSize();
      final totalProgress = await _queueRepository.getTotalProgress();
      
      final pending = await _queueRepository.getPending();
      final downloading = await _queueRepository.getDownloading();
      final completed = await _queueRepository.getCompleted();
      final failed = await _queueRepository.getFailed();
      
      return DownloadProgress(
        totalItems: totalSize,
        pendingItems: pending.length,
        downloadingItems: downloading.length,
        completedItems: completed.length,
        failedItems: failed.length,
        overallProgress: totalProgress,
      );
    } catch (e) {
      return DownloadProgress(
        totalItems: 0,
        pendingItems: 0,
        downloadingItems: 0,
        completedItems: 0,
        failedItems: 0,
        overallProgress: 0.0,
      );
    }
  }
  
  /// Retries failed downloads
  Future<void> retryFailedDownloads() async {
    try {
      await _queueRepository.retryFailed();
    } catch (e) {
      throw Exception('Failed to retry downloads: ${e.toString()}');
    }
  }
  
  /// Pauses all downloads
  Future<void> pauseAll() async {
    _isDownloading = false;
  }
  
  /// Resumes downloads
  Future<void> resumeAll() async {
    if (!_isDownloading) {
      await startDownloads();
    }
  }
}

class DownloadProgress {
  final int totalItems;
  final int pendingItems;
  final int downloadingItems;
  final int completedItems;
  final int failedItems;
  final double overallProgress;
  
  DownloadProgress({
    required this.totalItems,
    required this.pendingItems,
    required this.downloadingItems,
    required this.completedItems,
    required this.failedItems,
    required this.overallProgress,
  });
  
  bool get isComplete => completedItems == totalItems && totalItems > 0;
  bool get hasFailures => failedItems > 0;
  bool get isActive => downloadingItems > 0;
}