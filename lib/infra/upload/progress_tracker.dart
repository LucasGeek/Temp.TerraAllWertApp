import 'dart:async';
import 'dart:math' as math;

import '../cache/models/cache_metadata.dart';
import '../logging/app_logger.dart';

/// Serviço de tracking de progresso melhorado para uploads/downloads
class ProgressTracker {
  final Map<String, StreamController<UploadProgress>> _progressControllers = {};
  final Map<String, StreamController<BatchUploadProgress>> _batchControllers = {};
  final Map<String, ProgressState> _progressStates = {};
  final Map<String, BatchProgressState> _batchStates = {};
  
  /// Obtém stream de progresso para um arquivo específico
  Stream<UploadProgress> getFileProgressStream(String fileId) {
    _progressControllers[fileId] ??= StreamController<UploadProgress>.broadcast();
    return _progressControllers[fileId]!.stream;
  }
  
  /// Obtém stream de progresso para batch upload
  Stream<BatchUploadProgress> getBatchProgressStream(String batchId) {
    _batchControllers[batchId] ??= StreamController<BatchUploadProgress>.broadcast();
    return _batchControllers[batchId]!.stream;
  }
  
  /// Inicia tracking de arquivo individual
  void startFileTracking({
    required String fileId,
    required int totalBytes,
    String? fileName,
  }) {
    final state = ProgressState(
      fileId: fileId,
      fileName: fileName,
      totalBytes: totalBytes,
      startTime: DateTime.now(),
    );
    _progressStates[fileId] = state;
    
    AppLogger.debug('Started progress tracking for file: $fileId ($totalBytes bytes)', tag: 'ProgressTracker');
  }
  
  /// Atualiza progresso de arquivo individual
  void updateFileProgress({
    required String fileId,
    required int bytesUploaded,
    UploadStatus? status,
    String? error,
  }) {
    final state = _progressStates[fileId];
    if (state == null) {
      AppLogger.warning('No progress state found for file: $fileId', tag: 'ProgressTracker');
      return;
    }
    
    final progress = state.totalBytes > 0 ? bytesUploaded / state.totalBytes : 0.0;
    final now = DateTime.now();
    
    // Calcular velocidade (bytes/segundo)
    final elapsedSeconds = now.difference(state.startTime).inMilliseconds / 1000.0;
    final speed = elapsedSeconds > 0 ? bytesUploaded / elapsedSeconds : 0.0;
    
    // Estimar tempo restante
    final remainingBytes = state.totalBytes - bytesUploaded;
    final estimatedSecondsLeft = speed > 0 ? remainingBytes / speed : 0.0;
    
    final uploadProgress = UploadProgress(
      fileId: fileId,
      status: status ?? UploadStatus.uploading,
      progress: math.min(progress, 1.0),
      bytesUploaded: bytesUploaded,
      totalBytes: state.totalBytes,
      startedAt: state.startTime,
      error: error,
    );
    
    // Atualizar state interno
    _progressStates[fileId] = state.copyWith(
      bytesUploaded: bytesUploaded,
      speed: speed,
      estimatedTimeLeft: Duration(seconds: estimatedSecondsLeft.round()),
      lastUpdate: now,
    );
    
    // Notificar listeners
    final controller = _progressControllers[fileId];
    if (controller != null && !controller.isClosed) {
      controller.add(uploadProgress);
    }
    
    AppLogger.debug(
      'Progress update: $fileId - ${(progress * 100).toStringAsFixed(1)}% '
      '(${_formatBytes(bytesUploaded)}/${_formatBytes(state.totalBytes)}) '
      'Speed: ${_formatSpeed(speed)}', 
      tag: 'ProgressTracker'
    );
  }
  
  /// Finaliza tracking de arquivo individual
  void completeFileTracking({
    required String fileId,
    required bool success,
    String? error,
  }) {
    final state = _progressStates[fileId];
    if (state == null) return;
    
    final finalProgress = UploadProgress(
      fileId: fileId,
      status: success ? UploadStatus.completed : UploadStatus.failed,
      progress: success ? 1.0 : 0.0,
      bytesUploaded: success ? state.totalBytes : state.bytesUploaded,
      totalBytes: state.totalBytes,
      startedAt: state.startTime,
      completedAt: DateTime.now(),
      error: error,
    );
    
    final controller = _progressControllers[fileId];
    if (controller != null && !controller.isClosed) {
      controller.add(finalProgress);
      controller.close();
    }
    
    _progressControllers.remove(fileId);
    _progressStates.remove(fileId);
    
    AppLogger.info(
      'Completed file tracking: $fileId - ${success ? 'SUCCESS' : 'FAILED'}${error != null ? ' ($error)' : ''}',
      tag: 'ProgressTracker'
    );
  }
  
  /// Inicia tracking de batch
  void startBatchTracking({
    required String batchId,
    required int totalFiles,
    required List<String> fileIds,
  }) {
    final state = BatchProgressState(
      batchId: batchId,
      totalFiles: totalFiles,
      fileIds: fileIds,
      startTime: DateTime.now(),
    );
    _batchStates[batchId] = state;
    
    AppLogger.info('Started batch tracking: $batchId ($totalFiles files)', tag: 'ProgressTracker');
  }
  
  /// Atualiza progresso do batch baseado nos arquivos individuais
  void updateBatchProgress({
    required String batchId,
    required Map<String, UploadProgress> fileProgress,
  }) {
    final state = _batchStates[batchId];
    if (state == null) return;
    
    int completedFiles = 0;
    int failedFiles = 0;
    double totalProgress = 0.0;
    
    for (final progress in fileProgress.values) {
      totalProgress += progress.progress;
      if (progress.status == UploadStatus.completed) {
        completedFiles++;
      } else if (progress.status == UploadStatus.failed) {
        failedFiles++;
      }
    }
    
    final overallProgress = state.totalFiles > 0 ? totalProgress / state.totalFiles : 0.0;
    
    final batchProgress = BatchUploadProgress(
      totalFiles: state.totalFiles,
      completedFiles: completedFiles,
      failedFiles: failedFiles,
      overallProgress: math.min(overallProgress, 1.0),
      fileProgress: Map.from(fileProgress),
    );
    
    // Atualizar state interno
    _batchStates[batchId] = state.copyWith(
      completedFiles: completedFiles,
      failedFiles: failedFiles,
      lastUpdate: DateTime.now(),
    );
    
    // Notificar listeners
    final controller = _batchControllers[batchId];
    if (controller != null && !controller.isClosed) {
      controller.add(batchProgress);
    }
    
    AppLogger.debug(
      'Batch progress: $batchId - ${(overallProgress * 100).toStringAsFixed(1)}% '
      '($completedFiles completed, $failedFiles failed of ${state.totalFiles})',
      tag: 'ProgressTracker'
    );
  }
  
  /// Finaliza tracking de batch
  void completeBatchTracking({
    required String batchId,
    required int successCount,
    required int failureCount,
  }) {
    final state = _batchStates[batchId];
    if (state == null) return;
    
    final controller = _batchControllers[batchId];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    
    _batchControllers.remove(batchId);
    _batchStates.remove(batchId);
    
    final duration = DateTime.now().difference(state.startTime);
    AppLogger.info(
      'Completed batch tracking: $batchId - $successCount success, $failureCount failed '
      'in ${duration.inSeconds}s',
      tag: 'ProgressTracker'
    );
  }
  
  /// Cancela tracking de arquivo
  void cancelFileTracking(String fileId) {
    final controller = _progressControllers[fileId];
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
    _progressControllers.remove(fileId);
    _progressStates.remove(fileId);
    
    AppLogger.debug('Cancelled file tracking: $fileId', tag: 'ProgressTracker');
  }
  
  /// Obtém estatísticas atuais
  ProgressStats getStats() {
    final activeFiles = _progressStates.length;
    final activeBatches = _batchStates.length;
    
    int totalActiveUploads = 0;
    int totalBytes = 0;
    int uploadedBytes = 0;
    
    for (final state in _progressStates.values) {
      totalActiveUploads++;
      totalBytes += state.totalBytes;
      uploadedBytes += state.bytesUploaded;
    }
    
    return ProgressStats(
      activeFiles: activeFiles,
      activeBatches: activeBatches,
      totalActiveUploads: totalActiveUploads,
      totalBytes: totalBytes,
      uploadedBytes: uploadedBytes,
      overallProgress: totalBytes > 0 ? uploadedBytes / totalBytes : 0.0,
    );
  }
  
  /// Limpa todos os trackings
  void clear() {
    for (final controller in _progressControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    
    for (final controller in _batchControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    
    _progressControllers.clear();
    _batchControllers.clear();
    _progressStates.clear();
    _batchStates.clear();
    
    AppLogger.info('Cleared all progress tracking', tag: 'ProgressTracker');
  }
  
  /// Dispose de todos os recursos
  void dispose() {
    clear();
  }
  
  /// Formata bytes para exibição
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// Formata velocidade para exibição
  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(1)} B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

/// Estado interno de progresso de arquivo
class ProgressState {
  final String fileId;
  final String? fileName;
  final int totalBytes;
  final int bytesUploaded;
  final double speed;
  final Duration? estimatedTimeLeft;
  final DateTime startTime;
  final DateTime? lastUpdate;
  
  ProgressState({
    required this.fileId,
    this.fileName,
    required this.totalBytes,
    this.bytesUploaded = 0,
    this.speed = 0.0,
    this.estimatedTimeLeft,
    required this.startTime,
    this.lastUpdate,
  });
  
  ProgressState copyWith({
    int? bytesUploaded,
    double? speed,
    Duration? estimatedTimeLeft,
    DateTime? lastUpdate,
  }) {
    return ProgressState(
      fileId: fileId,
      fileName: fileName,
      totalBytes: totalBytes,
      bytesUploaded: bytesUploaded ?? this.bytesUploaded,
      speed: speed ?? this.speed,
      estimatedTimeLeft: estimatedTimeLeft ?? this.estimatedTimeLeft,
      startTime: startTime,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// Estado interno de progresso de batch
class BatchProgressState {
  final String batchId;
  final int totalFiles;
  final List<String> fileIds;
  final int completedFiles;
  final int failedFiles;
  final DateTime startTime;
  final DateTime? lastUpdate;
  
  BatchProgressState({
    required this.batchId,
    required this.totalFiles,
    required this.fileIds,
    this.completedFiles = 0,
    this.failedFiles = 0,
    required this.startTime,
    this.lastUpdate,
  });
  
  BatchProgressState copyWith({
    int? completedFiles,
    int? failedFiles,
    DateTime? lastUpdate,
  }) {
    return BatchProgressState(
      batchId: batchId,
      totalFiles: totalFiles,
      fileIds: fileIds,
      completedFiles: completedFiles ?? this.completedFiles,
      failedFiles: failedFiles ?? this.failedFiles,
      startTime: startTime,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// Estatísticas gerais de progresso
class ProgressStats {
  final int activeFiles;
  final int activeBatches;
  final int totalActiveUploads;
  final int totalBytes;
  final int uploadedBytes;
  final double overallProgress;
  
  ProgressStats({
    required this.activeFiles,
    required this.activeBatches,
    required this.totalActiveUploads,
    required this.totalBytes,
    required this.uploadedBytes,
    required this.overallProgress,
  });
}