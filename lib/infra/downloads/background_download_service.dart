import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../logging/app_logger.dart';

/// Serviço de downloads em background usando background_downloader
/// Gerencia downloads de arquivos grandes com suporte a progresso e pausa/resume
class BackgroundDownloadService {
  static final BackgroundDownloadService _instance = BackgroundDownloadService._internal();
  factory BackgroundDownloadService() => _instance;
  BackgroundDownloadService._internal();

  bool _initialized = false;
  final Map<String, StreamController<DownloadProgress>> _progressControllers = {};
  final Map<String, StreamController<DownloadStatus>> _statusControllers = {};

  /// Inicializa o serviço de downloads
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configurar notificações (apenas mobile)
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        FileDownloader().configureNotification(
          running: const TaskNotification(
            'Baixando {filename}',
            'Progresso: {progress} • Velocidade: {networkSpeed}',
          ),
          complete: const TaskNotification(
            'Download concluído',
            '{filename} foi baixado com sucesso',
          ),
          error: const TaskNotification(
            'Erro no download',
            'Falha ao baixar {filename}',
          ),
          paused: const TaskNotification(
            'Download pausado',
            '{filename} está pausado',
          ),
          progressBar: true,
        );
      }

      // Configurar callbacks para updates
      FileDownloader().registerCallbacks(
        taskStatusCallback: _onStatusUpdate,
        taskProgressCallback: _onProgressUpdate,
      );

      // Configurar para rastrear tarefas no banco
      await FileDownloader().trackTasks();

      // Iniciar o downloader (processa tarefas pendentes)
      await FileDownloader().start();

      _initialized = true;
      AppLogger.info('BackgroundDownloadService initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize BackgroundDownloadService: $e');
      throw Exception('Failed to initialize download service: $e');
    }
  }

  /// Inicia o download de um arquivo
  /// 
  /// [url] - URL do arquivo para download
  /// [filename] - Nome do arquivo local
  /// [directory] - Diretório de destino (relativo ao diretório de documentos)
  /// [metadata] - Metadados opcionais para o download
  /// 
  /// Retorna o ID da tarefa de download
  Future<String> startDownload({
    required String url,
    required String filename,
    String? directory,
    String? metadata,
    bool allowPause = true,
    bool requiresWiFi = false,
    int retries = 3,
  }) async {
    await _ensureInitialized();

    try {
      // Criar task de download
      final task = DownloadTask(
        url: url,
        filename: filename,
        directory: directory ?? 'downloads',
        baseDirectory: BaseDirectory.applicationDocuments,
        updates: Updates.statusAndProgress,
        allowPause: allowPause,
        requiresWiFi: requiresWiFi,
        retries: retries,
        metaData: metadata ?? '',
        displayName: filename,
      );

      // Criar streams para progresso e status
      _progressControllers[task.taskId] = StreamController<DownloadProgress>.broadcast();
      _statusControllers[task.taskId] = StreamController<DownloadStatus>.broadcast();

      // Enfileirar download
      final success = await FileDownloader().enqueue(task);
      
      if (success) {
        AppLogger.info('Download started: $filename (taskId: ${task.taskId})');
        return task.taskId;
      } else {
        throw Exception('Failed to enqueue download task');
      }
    } catch (e) {
      AppLogger.error('Failed to start download for $filename: $e');
      throw Exception('Failed to start download: $e');
    }
  }

  /// Pausa um download
  Future<bool> pauseDownload(String taskId) async {
    await _ensureInitialized();

    try {
      final task = await FileDownloader().taskForId(taskId);
      if (task != null && task is DownloadTask) {
        final success = await FileDownloader().pause(task);
        AppLogger.info('Download ${success ? 'paused' : 'pause failed'}: $taskId');
        return success;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to pause download $taskId: $e');
      return false;
    }
  }

  /// Resume um download pausado
  Future<bool> resumeDownload(String taskId) async {
    await _ensureInitialized();

    try {
      final task = await FileDownloader().taskForId(taskId);
      if (task != null && task is DownloadTask) {
        final success = await FileDownloader().resume(task);
        AppLogger.info('Download ${success ? 'resumed' : 'resume failed'}: $taskId');
        return success;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to resume download $taskId: $e');
      return false;
    }
  }

  /// Cancela um download
  Future<bool> cancelDownload(String taskId) async {
    await _ensureInitialized();

    try {
      final success = await FileDownloader().cancelTaskWithId(taskId);
      
      // Limpar streams
      _progressControllers[taskId]?.close();
      _statusControllers[taskId]?.close();
      _progressControllers.remove(taskId);
      _statusControllers.remove(taskId);
      
      AppLogger.info('Download ${success ? 'cancelled' : 'cancel failed'}: $taskId');
      return success;
    } catch (e) {
      AppLogger.error('Failed to cancel download $taskId: $e');
      return false;
    }
  }

  /// Obtém o status atual de um download
  Future<DownloadTaskInfo?> getDownloadInfo(String taskId) async {
    await _ensureInitialized();

    try {
      final record = await FileDownloader().database.recordForId(taskId);
      if (record != null) {
        return DownloadTaskInfo(
          taskId: record.taskId,
          filename: record.task.filename,
          url: record.task.url,
          status: _mapTaskStatus(record.status),
          progress: record.progress,
          expectedFileSize: record.expectedFileSize,
          directory: record.task.directory,
        );
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get download info for $taskId: $e');
      return null;
    }
  }

  /// Stream de progresso de um download específico
  Stream<DownloadProgress>? getProgressStream(String taskId) {
    return _progressControllers[taskId]?.stream;
  }

  /// Stream de status de um download específico
  Stream<DownloadStatus>? getStatusStream(String taskId) {
    return _statusControllers[taskId]?.stream;
  }

  /// Lista todos os downloads ativos
  Future<List<String>> getActiveDownloads() async {
    await _ensureInitialized();
    return await FileDownloader().allTaskIds();
  }

  /// Cancela todos os downloads
  Future<void> cancelAllDownloads() async {
    await _ensureInitialized();
    
    try {
      await FileDownloader().cancelAll();
      
      // Limpar todos os streams
      for (final controller in _progressControllers.values) {
        controller.close();
      }
      for (final controller in _statusControllers.values) {
        controller.close();
      }
      _progressControllers.clear();
      _statusControllers.clear();
      
      AppLogger.info('All downloads cancelled');
    } catch (e) {
      AppLogger.error('Failed to cancel all downloads: $e');
    }
  }

  /// Obtém o caminho completo de um arquivo baixado
  Future<String?> getDownloadedFilePath(String taskId) async {
    try {
      final info = await getDownloadInfo(taskId);
      if (info != null && info.status == DownloadStatus.completed) {
        final directory = await getApplicationDocumentsDirectory();
        return '${directory.path}/${info.directory}/${info.filename}';
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get downloaded file path for $taskId: $e');
      return null;
    }
  }

  /// Callback para atualizações de status
  void _onStatusUpdate(TaskStatusUpdate update) {
    final taskId = update.task.taskId;
    final status = _mapTaskStatus(update.status);
    
    _statusControllers[taskId]?.add(status);
    
    AppLogger.debug(
      'Download status update: $taskId -> ${update.status}',
      tag: 'BackgroundDownloader',
    );

    // Limpar streams quando o download termina
    if (update.status.isFinalState) {
      Future.delayed(const Duration(seconds: 30), () {
        _progressControllers[taskId]?.close();
        _statusControllers[taskId]?.close();
        _progressControllers.remove(taskId);
        _statusControllers.remove(taskId);
      });
    }
  }

  /// Callback para atualizações de progresso
  void _onProgressUpdate(TaskProgressUpdate update) {
    final taskId = update.task.taskId;
    final progress = DownloadProgress(
      taskId: taskId,
      progress: update.progress,
      expectedFileSize: update.expectedFileSize,
      networkSpeed: update.networkSpeed,
      timeRemaining: update.timeRemaining,
    );
    
    _progressControllers[taskId]?.add(progress);
  }

  /// Mapeia TaskStatus para DownloadStatus
  DownloadStatus _mapTaskStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.enqueued:
        return DownloadStatus.enqueued;
      case TaskStatus.running:
        return DownloadStatus.running;
      case TaskStatus.complete:
        return DownloadStatus.completed;
      case TaskStatus.canceled:
        return DownloadStatus.cancelled;
      case TaskStatus.failed:
        return DownloadStatus.failed;
      case TaskStatus.paused:
        return DownloadStatus.paused;
      case TaskStatus.notFound:
        return DownloadStatus.failed;
      case TaskStatus.waitingToRetry:
        return DownloadStatus.retrying;
    }
  }

  /// Garante que o serviço está inicializado
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Dispose do serviço
  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    for (final controller in _statusControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _statusControllers.clear();
  }
}

/// Status de um download
enum DownloadStatus {
  enqueued,
  running,
  paused,
  completed,
  cancelled,
  failed,
  retrying,
}

/// Informações de progresso de um download
class DownloadProgress {
  final String taskId;
  final double progress;
  final int expectedFileSize;
  final double networkSpeed;
  final Duration timeRemaining;

  DownloadProgress({
    required this.taskId,
    required this.progress,
    required this.expectedFileSize,
    required this.networkSpeed,
    required this.timeRemaining,
  });

  double get progressPercentage => progress * 100;

  String get formattedProgress => '${progressPercentage.toStringAsFixed(1)}%';

  String get formattedFileSize {
    if (expectedFileSize <= 0) return 'Desconhecido';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = expectedFileSize.toDouble();
    var unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  String get formattedNetworkSpeed {
    if (networkSpeed <= 0) return 'Desconhecido';
    
    const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var speed = networkSpeed;
    var unitIndex = 0;
    
    while (speed >= 1024 && unitIndex < units.length - 1) {
      speed /= 1024;
      unitIndex++;
    }
    
    return '${speed.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  String get formattedTimeRemaining {
    if (timeRemaining == Duration.zero) return 'Calculando...';
    
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;
    final seconds = timeRemaining.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Informações de uma tarefa de download
class DownloadTaskInfo {
  final String taskId;
  final String filename;
  final String url;
  final DownloadStatus status;
  final double progress;
  final int expectedFileSize;
  final String directory;

  DownloadTaskInfo({
    required this.taskId,
    required this.filename,
    required this.url,
    required this.status,
    required this.progress,
    required this.expectedFileSize,
    required this.directory,
  });
}