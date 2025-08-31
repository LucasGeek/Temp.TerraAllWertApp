import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../platform/platform_service.dart';

enum DownloadStatus { pending, downloading, completed, failed, cancelled }

class DownloadTask {
  final String id;
  final String url;
  final String fileName;
  final String? savePath;
  final DownloadStatus status;
  final int? totalBytes;
  final int downloadedBytes;
  final double progress;
  final String? error;
  final CancelToken? cancelToken;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    this.savePath,
    required this.status,
    this.totalBytes,
    this.downloadedBytes = 0,
    this.progress = 0.0,
    this.error,
    this.cancelToken,
  });

  DownloadTask copyWith({
    String? id,
    String? url,
    String? fileName,
    String? savePath,
    DownloadStatus? status,
    int? totalBytes,
    int? downloadedBytes,
    double? progress,
    String? error,
    CancelToken? cancelToken,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      savePath: savePath ?? this.savePath,
      status: status ?? this.status,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      cancelToken: cancelToken ?? this.cancelToken,
    );
  }
}

abstract class DownloadManager {
  Future<void> initialize();
  Future<String> startDownload(String url, String fileName, {String? customPath});
  Future<void> cancelDownload(String taskId);
  Future<void> pauseDownload(String taskId);
  Future<void> resumeDownload(String taskId);
  Future<void> clearCompleted();
  
  Stream<DownloadTask> get downloadStream;
  List<DownloadTask> get activeDownloads;
  Future<String> get downloadDirectory;
}

class DownloadManagerImpl implements DownloadManager {
  final Dio _dio = Dio();
  final Map<String, DownloadTask> _tasks = {};
  final StreamController<DownloadTask> _controller = StreamController.broadcast();
  
  String? _downloadDir;

  @override
  Future<void> initialize() async {
    if (PlatformService.supportsFileSystem) {
      final dir = await _getDownloadDirectory();
      _downloadDir = dir.path;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  @override
  Future<String> get downloadDirectory async {
    if (_downloadDir != null) return _downloadDir!;
    
    final dir = await _getDownloadDirectory();
    _downloadDir = dir.path;
    return _downloadDir!;
  }

  Future<Directory> _getDownloadDirectory() async {
    if (PlatformService.isWeb) {
      throw UnsupportedError('File system not supported on web');
    }

    Directory baseDir;
    
    if (PlatformService.isMobile) {
      if (PlatformService.current == AppPlatform.android) {
        baseDir = Directory('/storage/emulated/0/Download/TerraAllwert');
      } else {
        baseDir = await getApplicationDocumentsDirectory();
        baseDir = Directory('${baseDir.path}/Downloads');
      }
    } else {
      baseDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      baseDir = Directory('${baseDir.path}/TerraAllwert');
    }

    return baseDir;
  }

  @override
  Future<String> startDownload(String url, String fileName, {String? customPath}) async {
    if (PlatformService.isWeb) {
      return _startWebDownload(url, fileName);
    }

    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final downloadDir = customPath ?? await downloadDirectory;
    final filePath = '$downloadDir/$fileName';
    final cancelToken = CancelToken();

    final task = DownloadTask(
      id: taskId,
      url: url,
      fileName: fileName,
      savePath: filePath,
      status: DownloadStatus.downloading,
      cancelToken: cancelToken,
    );

    _tasks[taskId] = task;
    _controller.add(task);

    try {
      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final updatedTask = task.copyWith(
            downloadedBytes: received,
            totalBytes: total,
            progress: total > 0 ? received / total : 0.0,
          );
          _tasks[taskId] = updatedTask;
          _controller.add(updatedTask);
        },
      );

      final completedTask = task.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
      );
      _tasks[taskId] = completedTask;
      _controller.add(completedTask);

    } catch (error) {
      final failedTask = task.copyWith(
        status: error is DioException && error.type == DioExceptionType.cancel
            ? DownloadStatus.cancelled
            : DownloadStatus.failed,
        error: error.toString(),
      );
      _tasks[taskId] = failedTask;
      _controller.add(failedTask);
    }

    return taskId;
  }

  String _startWebDownload(String url, String fileName) {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final task = DownloadTask(
      id: taskId,
      url: url,
      fileName: fileName,
      status: DownloadStatus.downloading,
    );

    _tasks[taskId] = task;
    _controller.add(task);

    _webDownload(url, fileName, taskId);
    return taskId;
  }

  Future<void> _webDownload(String url, String fileName, String taskId) async {
    try {
      // Para web, usamos download através do navegador
      final response = await _dio.get<Uint8List>(
        url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (_tasks.containsKey(taskId)) {
            final task = _tasks[taskId]!;
            final updatedTask = task.copyWith(
              downloadedBytes: received,
              totalBytes: total,
              progress: total > 0 ? received / total : 0.0,
            );
            _tasks[taskId] = updatedTask;
            _controller.add(updatedTask);
          }
        },
      );

      if (response.data != null) {
        // Simula download no navegador
        _triggerWebDownload(response.data!, fileName);
        
        final task = _tasks[taskId]!;
        final completedTask = task.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
        );
        _tasks[taskId] = completedTask;
        _controller.add(completedTask);
      }

    } catch (error) {
      if (_tasks.containsKey(taskId)) {
        final task = _tasks[taskId]!;
        final failedTask = task.copyWith(
          status: DownloadStatus.failed,
          error: error.toString(),
        );
        _tasks[taskId] = failedTask;
        _controller.add(failedTask);
      }
    }
  }

  void _triggerWebDownload(Uint8List data, String fileName) {
    // Implementação específica para web seria feita aqui
    // usando dart:html ou js interop para trigger do download
    // Por enquanto apenas registramos no debug
    if (kDebugMode) {
      print('Web download triggered for: $fileName (${data.length} bytes)');
    }
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    final task = _tasks[taskId];
    if (task != null && task.cancelToken != null) {
      task.cancelToken!.cancel();
      
      final cancelledTask = task.copyWith(
        status: DownloadStatus.cancelled,
      );
      _tasks[taskId] = cancelledTask;
      _controller.add(cancelledTask);
    }
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    // Implementação específica de pause seria mais complexa
    // Por enquanto, cancelamos o download
    await cancelDownload(taskId);
  }

  @override
  Future<void> resumeDownload(String taskId) async {
    final task = _tasks[taskId];
    if (task != null && task.status == DownloadStatus.cancelled) {
      // Para resumir, iniciamos um novo download
      await startDownload(task.url, task.fileName, customPath: task.savePath);
    }
  }

  @override
  Future<void> clearCompleted() async {
    _tasks.removeWhere((key, task) => 
      task.status == DownloadStatus.completed || 
      task.status == DownloadStatus.failed ||
      task.status == DownloadStatus.cancelled
    );
  }

  @override
  Stream<DownloadTask> get downloadStream => _controller.stream;

  @override
  List<DownloadTask> get activeDownloads {
    return _tasks.values.where((task) => 
      task.status == DownloadStatus.downloading || 
      task.status == DownloadStatus.pending
    ).toList();
  }

  void dispose() {
    _controller.close();
  }
}

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return DownloadManagerImpl();
});

final downloadManagerInitProvider = FutureProvider<void>((ref) async {
  final downloadManager = ref.watch(downloadManagerProvider);
  await downloadManager.initialize();
});

final activeDownloadsProvider = StreamProvider<List<DownloadTask>>((ref) {
  final downloadManager = ref.watch(downloadManagerProvider);
  return downloadManager.downloadStream.map((task) => downloadManager.activeDownloads);
});