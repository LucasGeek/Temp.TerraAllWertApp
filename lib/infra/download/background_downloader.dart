import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';

/// Dados de configuração para download em background
class DownloadConfig {
  final String url;
  final String fileName;
  final String routeId;
  final String? fileId;
  final Map<String, String>? headers;
  final Duration? timeout;
  
  const DownloadConfig({
    required this.url,
    required this.fileName,
    required this.routeId,
    this.fileId,
    this.headers,
    this.timeout,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'fileName': fileName,
      'routeId': routeId,
      'fileId': fileId,
      'headers': headers,
      'timeout': timeout?.inMilliseconds,
    };
  }
  
  factory DownloadConfig.fromMap(Map<String, dynamic> map) {
    return DownloadConfig(
      url: map['url'],
      fileName: map['fileName'],
      routeId: map['routeId'],
      fileId: map['fileId'],
      headers: map['headers'] != null ? Map<String, String>.from(map['headers']) : null,
      timeout: map['timeout'] != null ? Duration(milliseconds: map['timeout']) : null,
    );
  }
}

/// Progresso de download
class DownloadProgress {
  final String fileId;
  final int bytesDownloaded;
  final int totalBytes;
  final double progress;
  final DownloadStatus status;
  final String? error;
  final double? speed; // bytes por segundo
  final Duration? estimatedTimeLeft;
  final String? filePath;

  const DownloadProgress({
    required this.fileId,
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.progress,
    required this.status,
    this.error,
    this.speed,
    this.estimatedTimeLeft,
    this.filePath,
  });

  DownloadProgress copyWith({
    String? fileId,
    int? bytesDownloaded,
    int? totalBytes,
    double? progress,
    DownloadStatus? status,
    String? error,
    double? speed,
    Duration? estimatedTimeLeft,
    String? filePath,
  }) {
    return DownloadProgress(
      fileId: fileId ?? this.fileId,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error ?? this.error,
      speed: speed ?? this.speed,
      estimatedTimeLeft: estimatedTimeLeft ?? this.estimatedTimeLeft,
      filePath: filePath ?? this.filePath,
    );
  }
}

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
  paused,
}

/// Resultado do download
class DownloadResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int? fileSize;
  final Duration? downloadTime;

  const DownloadResult({
    required this.success,
    this.filePath,
    this.error,
    this.fileSize,
    this.downloadTime,
  });
}

/// Service de download em background que não bloqueia a UI
class BackgroundDownloader {
  static final BackgroundDownloader _instance = BackgroundDownloader._internal();
  factory BackgroundDownloader() => _instance;
  BackgroundDownloader._internal();

  final Map<String, StreamController<DownloadProgress>> _progressControllers = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final Dio _dio = Dio();

  /// Inicia download de arquivo em background
  Future<DownloadResult> downloadFile({
    required DownloadConfig config,
    Function(DownloadProgress)? onProgress,
  }) async {
    if (kIsWeb) {
      AppLogger.warning('Background download not supported on web platform', tag: 'Download');
      return const DownloadResult(
        success: false,
        error: 'Downloads in background not supported on web',
      );
    }

    final fileId = config.fileId ?? config.fileName;
    AppLogger.info('Starting background download for: $fileId', tag: 'Download');

    try {
      // Configurar diretório de download
      final downloadDir = await _getDownloadDirectory(config.routeId);
      final filePath = path.join(downloadDir.path, config.fileName);

      // Verificar se arquivo já existe (offline-first)
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        AppLogger.info('File already exists offline: $filePath', tag: 'Download');
        final fileSize = await existingFile.length();
        
        final progress = DownloadProgress(
          fileId: fileId,
          bytesDownloaded: fileSize,
          totalBytes: fileSize,
          progress: 1.0,
          status: DownloadStatus.completed,
          filePath: filePath,
        );
        
        onProgress?.call(progress);
        
        return DownloadResult(
          success: true,
          filePath: filePath,
          fileSize: fileSize,
          downloadTime: Duration.zero,
        );
      }

      // Configurar progresso
      final progressController = StreamController<DownloadProgress>.broadcast();
      _progressControllers[fileId] = progressController;
      
      if (onProgress != null) {
        progressController.stream.listen(onProgress);
      }

      // Configurar cancelamento
      final cancelToken = CancelToken();
      _cancelTokens[fileId] = cancelToken;

      // Executar download em isolate para não bloquear UI
      final result = await _performDownloadInBackground(
        config: config,
        filePath: filePath,
        fileId: fileId,
        cancelToken: cancelToken,
      );

      // Cleanup
      _progressControllers.remove(fileId)?.close();
      _cancelTokens.remove(fileId);

      return result;

    } catch (e) {
      AppLogger.error('Download failed for $fileId: $e', tag: 'Download');
      
      // Cleanup em caso de erro
      _progressControllers.remove(fileId)?.close();
      _cancelTokens.remove(fileId);
      
      return DownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Executa download em background usando compute para não bloquear UI
  Future<DownloadResult> _performDownloadInBackground({
    required DownloadConfig config,
    required String filePath,
    required String fileId,
    required CancelToken cancelToken,
  }) async {
    final startTime = DateTime.now();
    
    try {
      // Emitir progresso inicial
      _emitProgress(fileId, DownloadProgress(
        fileId: fileId,
        bytesDownloaded: 0,
        totalBytes: 0,
        progress: 0.0,
        status: DownloadStatus.downloading,
      ));

      // Configurar Dio para download
      final options = Options(
        headers: config.headers,
        responseType: ResponseType.bytes,
        receiveTimeout: config.timeout ?? const Duration(minutes: 10),
        sendTimeout: config.timeout ?? const Duration(minutes: 5),
      );

      // Realizar download com progresso
      final response = await _dio.get<Uint8List>(
        config.url,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          final currentTime = DateTime.now();
          final elapsed = currentTime.difference(startTime).inMilliseconds;
          
          // Calcular velocidade e tempo estimado
          double? speed;
          Duration? estimatedTimeLeft;
          
          if (elapsed > 0) {
            speed = (received / elapsed) * 1000; // bytes por segundo
            if (speed > 0 && total > received) {
              final remainingBytes = total - received;
              estimatedTimeLeft = Duration(seconds: (remainingBytes / speed).round());
            }
          }

          _emitProgress(fileId, DownloadProgress(
            fileId: fileId,
            bytesDownloaded: received,
            totalBytes: total,
            progress: progress,
            status: DownloadStatus.downloading,
            speed: speed,
            estimatedTimeLeft: estimatedTimeLeft,
          ));
        },
      );

      if (response.data != null) {
        // Salvar arquivo usando compute para não bloquear UI
        await compute(_saveFileInBackground, {
          'data': response.data!,
          'filePath': filePath,
        });

        final endTime = DateTime.now();
        final downloadTime = endTime.difference(startTime);
        
        // Emitir progresso final
        _emitProgress(fileId, DownloadProgress(
          fileId: fileId,
          bytesDownloaded: response.data!.length,
          totalBytes: response.data!.length,
          progress: 1.0,
          status: DownloadStatus.completed,
          filePath: filePath,
        ));

        AppLogger.info(
          'Download completed: $fileId (${response.data!.length} bytes in ${downloadTime.inSeconds}s)',
          tag: 'Download',
        );

        return DownloadResult(
          success: true,
          filePath: filePath,
          fileSize: response.data!.length,
          downloadTime: downloadTime,
        );
      }

      throw Exception('No data received from server');

    } catch (e) {
      AppLogger.error('Background download error: $e', tag: 'Download');
      
      _emitProgress(fileId, DownloadProgress(
        fileId: fileId,
        bytesDownloaded: 0,
        totalBytes: 0,
        progress: 0.0,
        status: DownloadStatus.failed,
        error: e.toString(),
      ));

      return DownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Salva arquivo em background usando compute
  static Future<void> _saveFileInBackground(Map<String, dynamic> params) async {
    final Uint8List data = params['data'];
    final String filePath = params['filePath'];
    
    final file = File(filePath);
    await file.writeAsBytes(data);
  }

  /// Cancela download em progresso
  Future<bool> cancelDownload(String fileId) async {
    final cancelToken = _cancelTokens[fileId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled by user');
      
      _emitProgress(fileId, DownloadProgress(
        fileId: fileId,
        bytesDownloaded: 0,
        totalBytes: 0,
        progress: 0.0,
        status: DownloadStatus.cancelled,
      ));
      
      // Cleanup
      _progressControllers.remove(fileId)?.close();
      _cancelTokens.remove(fileId);
      
      AppLogger.info('Download cancelled: $fileId', tag: 'Download');
      return true;
    }
    return false;
  }

  /// Stream de progresso para um download específico
  Stream<DownloadProgress>? getProgressStream(String fileId) {
    return _progressControllers[fileId]?.stream;
  }

  /// Verifica se um download está em progresso
  bool isDownloading(String fileId) {
    return _cancelTokens.containsKey(fileId);
  }

  /// Obtém diretório de download para uma rota específica
  Future<Directory> _getDownloadDirectory(String routeId) async {
    final appDir = await getApplicationSupportDirectory();
    final downloadDir = Directory(path.join(appDir.path, 'downloads', routeId));
    
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    
    return downloadDir;
  }

  /// Emite progresso para listeners
  void _emitProgress(String fileId, DownloadProgress progress) {
    final controller = _progressControllers[fileId];
    if (controller != null && !controller.isClosed) {
      controller.add(progress);
    }
  }

  /// Limpa todos os downloads
  Future<void> clearAllDownloads() async {
    // Cancelar downloads ativos
    for (final entry in _cancelTokens.entries) {
      if (!entry.value.isCancelled) {
        entry.value.cancel('Clearing all downloads');
      }
    }
    
    // Fechar streams
    for (final controller in _progressControllers.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    
    _progressControllers.clear();
    _cancelTokens.clear();
    
    AppLogger.info('All downloads cleared', tag: 'Download');
  }

  /// Obtém estatísticas de downloads
  Map<String, dynamic> getDownloadStats() {
    return {
      'activeDownloads': _cancelTokens.length,
      'progressStreams': _progressControllers.length,
      'platform': kIsWeb ? 'web' : 'native',
      'supportsBackground': !kIsWeb,
    };
  }

  /// Dispose - limpar recursos
  Future<void> dispose() async {
    await clearAllDownloads();
    _dio.close();
  }
}