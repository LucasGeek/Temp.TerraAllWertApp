import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';
import '../downloads/background_download_service.dart';

/// Informações de versão do ZIP
class ZipVersion {
  final String routeId;
  final String version;
  final DateTime downloadedAt;
  final int fileCount;
  final int totalSize;
  final String zipPath;
  final String extractedPath;

  const ZipVersion({
    required this.routeId,
    required this.version,
    required this.downloadedAt,
    required this.fileCount,
    required this.totalSize,
    required this.zipPath,
    required this.extractedPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'version': version,
      'downloadedAt': downloadedAt.toIso8601String(),
      'fileCount': fileCount,
      'totalSize': totalSize,
      'zipPath': zipPath,
      'extractedPath': extractedPath,
    };
  }

  factory ZipVersion.fromMap(Map<String, dynamic> map) {
    return ZipVersion(
      routeId: map['routeId'],
      version: map['version'],
      downloadedAt: DateTime.parse(map['downloadedAt']),
      fileCount: map['fileCount'],
      totalSize: map['totalSize'],
      zipPath: map['zipPath'],
      extractedPath: map['extractedPath'],
    );
  }
}

/// Resultado de download e extração de ZIP
class ZipDownloadResult {
  final bool success;
  final String? error;
  final ZipVersion? version;
  final int? extractedFiles;
  final Duration? totalTime;

  const ZipDownloadResult({
    required this.success,
    this.error,
    this.version,
    this.extractedFiles,
    this.totalTime,
  });
}

/// Progresso de operação ZIP
class ZipProgress {
  final String phase; // 'downloading', 'extracting', 'cleanup'
  final double progress; // 0.0 - 1.0
  final String? currentFile;
  final int? processedFiles;
  final int? totalFiles;

  const ZipProgress({
    required this.phase,
    required this.progress,
    this.currentFile,
    this.processedFiles,
    this.totalFiles,
  });
}

/// Gerenciador de downloads ZIP com versionamento e limpeza automática
class ZipManager {
  static final ZipManager _instance = ZipManager._internal();
  factory ZipManager() => _instance;
  ZipManager._internal();

  final BackgroundDownloadService _downloader = BackgroundDownloadService();
  final Map<String, StreamController<ZipProgress>> _progressControllers = {};
  final Map<String, ZipVersion> _currentVersions = {};

  /// Baixa e extrai ZIP com versionamento automático
  Future<ZipDownloadResult> downloadAndExtractZip({
    required String zipUrl,
    required String routeId,
    required String version,
    Function(ZipProgress)? onProgress,
    bool cleanupOldVersions = true,
  }) async {
    if (kIsWeb) {
      AppLogger.warning('ZIP operations not supported on web platform', tag: 'ZipManager');
      return const ZipDownloadResult(
        success: false,
        error: 'ZIP operations not supported on web',
      );
    }

    final startTime = DateTime.now();
    AppLogger.info('Starting ZIP download and extraction: $routeId v$version', tag: 'ZipManager');

    try {
      // Configurar progresso
      final progressController = StreamController<ZipProgress>.broadcast();
      _progressControllers[routeId] = progressController;
      
      if (onProgress != null) {
        progressController.stream.listen(onProgress);
      }

      // 1. Verificar se já existe essa versão
      final existingVersion = await _getExistingVersion(routeId, version);
      if (existingVersion != null) {
        _emitProgress(routeId, const ZipProgress(
          phase: 'completed',
          progress: 1.0,
        ));
        
        AppLogger.info('ZIP version already exists: $routeId v$version', tag: 'ZipManager');
        return ZipDownloadResult(
          success: true,
          version: existingVersion,
          extractedFiles: existingVersion.fileCount,
          totalTime: Duration.zero,
        );
      }

      // 2. Preparar diretórios
      final zipDir = await _getZipDirectory(routeId);
      final extractedDir = await _getExtractedDirectory(routeId, version);
      
      final zipFileName = '${routeId}_v$version.zip';
      final zipPath = path.join(zipDir.path, zipFileName);

      // 3. Download do ZIP
      _emitProgress(routeId, const ZipProgress(
        phase: 'downloading',
        progress: 0.0,
      ));

      final downloadResult = await _downloadZip(
        zipUrl: zipUrl,
        zipPath: zipPath,
        routeId: routeId,
        onProgress: (progress) {
          _emitProgress(routeId, ZipProgress(
            phase: 'downloading',
            progress: progress.progress * 0.7, // 70% para download
          ));
        },
      );

      if (downloadResult['success'] != true) {
        return ZipDownloadResult(
          success: false,
          error: 'Download failed: ${downloadResult['error']}',
        );
      }

      // 4. Extrair ZIP
      _emitProgress(routeId, const ZipProgress(
        phase: 'extracting',
        progress: 0.7,
      ));

      final extractionResult = await _extractZip(
        zipPath: zipPath,
        extractedDir: extractedDir,
        routeId: routeId,
        onProgress: (extractProgress) {
          _emitProgress(routeId, ZipProgress(
            phase: 'extracting',
            progress: 0.7 + (extractProgress * 0.25), // 25% para extração
            currentFile: extractProgress < 1.0 ? 'Extraindo arquivos...' : null,
          ));
        },
      );

      if (!extractionResult.success) {
        return ZipDownloadResult(
          success: false,
          error: 'Extraction failed: ${extractionResult.error}',
        );
      }

      // 5. Criar versão
      final zipFile = File(zipPath);
      final zipSize = await zipFile.length();
      
      final newVersion = ZipVersion(
        routeId: routeId,
        version: version,
        downloadedAt: DateTime.now(),
        fileCount: extractionResult.extractedFiles!,
        totalSize: zipSize,
        zipPath: zipPath,
        extractedPath: extractedDir.path,
      );

      // 6. Salvar versão atual
      _currentVersions[routeId] = newVersion;
      await _saveVersionInfo(newVersion);

      // 7. Limpeza de versões antigas
      if (cleanupOldVersions) {
        _emitProgress(routeId, const ZipProgress(
          phase: 'cleanup',
          progress: 0.95,
        ));
        
        await _cleanupOldVersions(routeId, version);
      }

      // 8. Progresso final
      _emitProgress(routeId, const ZipProgress(
        phase: 'completed',
        progress: 1.0,
      ));

      final endTime = DateTime.now();
      final totalTime = endTime.difference(startTime);

      AppLogger.info(
        'ZIP download and extraction completed: $routeId v$version (${extractionResult.extractedFiles} files in ${totalTime.inSeconds}s)',
        tag: 'ZipManager',
      );

      // Cleanup
      _progressControllers.remove(routeId)?.close();

      return ZipDownloadResult(
        success: true,
        version: newVersion,
        extractedFiles: extractionResult.extractedFiles,
        totalTime: totalTime,
      );

    } catch (e) {
      AppLogger.error('ZIP download and extraction failed: $routeId -> $e', tag: 'ZipManager');
      
      _emitProgress(routeId, ZipProgress(
        phase: 'error',
        progress: 0.0,
        currentFile: 'Erro: $e',
      ));

      // Cleanup
      _progressControllers.remove(routeId)?.close();

      return ZipDownloadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Baixa arquivo ZIP
  Future<Map<String, dynamic>> _downloadZip({
    required String zipUrl,
    required String zipPath,
    required String routeId,
    Function(dynamic)? onProgress,
  }) async {
    try {
      // Inicializar serviço se necessário
      await _downloader.initialize();

      // Iniciar download do ZIP
      final taskId = await _downloader.startDownload(
        url: zipUrl,
        filename: path.basename(zipPath),
        directory: 'offline_zips/$routeId',
        metadata: 'zip_$routeId',
        allowPause: true,
        requiresWiFi: false,
        retries: 3,
      );

      // Configurar stream de progresso se callback fornecido
      if (onProgress != null) {
        final progressStream = _downloader.getProgressStream(taskId);
        progressStream?.listen((progress) {
          onProgress.call(progress);
        });
      }

      // Aguardar conclusão do download
      final statusStream = _downloader.getStatusStream(taskId);
      
      await for (final status in statusStream ?? const Stream.empty()) {
        if (status == DownloadStatus.completed) {
          final filePath = await _downloader.getDownloadedFilePath(taskId);
          AppLogger.info('ZIP download completed: $routeId -> $filePath', tag: 'ZipManager');
          return {
            'success': true,
            'filePath': filePath,
            'taskId': taskId,
          };
        } else if (status == DownloadStatus.failed) {
          AppLogger.error('ZIP download failed: $routeId', tag: 'ZipManager');
          return {
            'success': false,
            'error': 'Download failed for ZIP: $routeId',
          };
        } else if (status == DownloadStatus.cancelled) {
          AppLogger.warning('ZIP download cancelled: $routeId', tag: 'ZipManager');
          return {
            'success': false,
            'error': 'Download was cancelled for ZIP: $routeId',
          };
        }
      }

      // Timeout ou stream vazio
      AppLogger.warning('ZIP download status unknown: $routeId', tag: 'ZipManager');
      return {
        'success': false,
        'error': 'Download status unknown for ZIP: $routeId',
      };

    } catch (e) {
      AppLogger.error('Failed to download ZIP $routeId: $e', tag: 'ZipManager');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Extrai ZIP usando compute para não bloquear UI
  Future<ExtractionResult> _extractZip({
    required String zipPath,
    required Directory extractedDir,
    required String routeId,
    Function(double)? onProgress,
  }) async {
    try {
      // Usar compute para extrair em background
      final result = await compute(_extractZipInBackground, {
        'zipPath': zipPath,
        'extractedPath': extractedDir.path,
        'routeId': routeId,
      });

      onProgress?.call(1.0);

      return ExtractionResult(
        success: result['success'],
        error: result['error'],
        extractedFiles: result['extractedFiles'],
      );

    } catch (e) {
      AppLogger.error('ZIP extraction error: $e', tag: 'ZipManager');
      return ExtractionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Extrai ZIP em background usando compute
  static Future<Map<String, dynamic>> _extractZipInBackground(Map<String, dynamic> params) async {
    final String zipPath = params['zipPath'];
    final String extractedPath = params['extractedPath'];

    try {
      // Ler arquivo ZIP
      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();

      // Decodificar arquivo ZIP
      final archive = ZipDecoder().decodeBytes(bytes);

      // Criar diretório de extração
      final extractDir = Directory(extractedPath);
      if (!await extractDir.exists()) {
        await extractDir.create(recursive: true);
      }

      int extractedFiles = 0;

      // Extrair cada arquivo
      for (final file in archive) {
        final filePath = path.join(extractedPath, file.name);
        
        if (file.isFile) {
          final outFile = File(filePath);
          
          // Criar diretórios pai se necessário
          await outFile.parent.create(recursive: true);
          
          // Escrever arquivo
          await outFile.writeAsBytes(file.content as List<int>);
          extractedFiles++;
        } else {
          // Criar diretório
          final outDir = Directory(filePath);
          await outDir.create(recursive: true);
        }
      }

      return {
        'success': true,
        'extractedFiles': extractedFiles,
        'error': null,
      };

    } catch (e) {
      return {
        'success': false,
        'extractedFiles': 0,
        'error': e.toString(),
      };
    }
  }

  /// Remove versões antigas mantendo apenas a mais recente
  Future<void> _cleanupOldVersions(String routeId, String currentVersion) async {
    try {
      AppLogger.info('Cleaning up old versions for route: $routeId', tag: 'ZipManager');

      // Obter diretório de ZIPs
      final zipDir = await _getZipDirectory(routeId);
      final extractedBaseDir = await _getExtractedBaseDirectory(routeId);

      if (!await zipDir.exists()) return;

      // Listar arquivos ZIP existentes
      final zipFiles = await zipDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.zip'))
          .cast<File>()
          .toList();

      // Listar diretórios extraídos
      List<Directory> extractedDirs = [];
      if (await extractedBaseDir.exists()) {
        extractedDirs = await extractedBaseDir
            .list()
            .where((entity) => entity is Directory)
            .cast<Directory>()
            .toList();
      }

      int removedFiles = 0;
      int removedDirs = 0;

      // Remover ZIPs antigos (manter apenas atual)
      for (final zipFile in zipFiles) {
        final fileName = path.basenameWithoutExtension(zipFile.path);
        if (!fileName.contains('v$currentVersion')) {
          await zipFile.delete();
          removedFiles++;
          AppLogger.debug('Removed old ZIP: ${zipFile.path}', tag: 'ZipManager');
        }
      }

      // Remover diretórios extraídos antigos
      for (final dir in extractedDirs) {
        final dirName = path.basename(dir.path);
        if (!dirName.contains('v$currentVersion')) {
          await dir.delete(recursive: true);
          removedDirs++;
          AppLogger.debug('Removed old extracted dir: ${dir.path}', tag: 'ZipManager');
        }
      }

      AppLogger.info(
        'Cleanup completed: removed $removedFiles ZIP files and $removedDirs directories',
        tag: 'ZipManager',
      );

    } catch (e) {
      AppLogger.error('Failed to cleanup old versions: $e', tag: 'ZipManager');
    }
  }

  /// Verifica se uma versão específica já existe
  Future<ZipVersion?> _getExistingVersion(String routeId, String version) async {
    try {
      final extractedDir = await _getExtractedDirectory(routeId, version);
      final zipDir = await _getZipDirectory(routeId);
      final zipPath = path.join(zipDir.path, '${routeId}_v$version.zip');

      // Verificar se tanto ZIP quanto pasta extraída existem
      if (await extractedDir.exists() && await File(zipPath).exists()) {
        // Carregar informações da versão
        final versionInfoFile = File(path.join(extractedDir.path, '.version_info.json'));
        if (await versionInfoFile.exists()) {
          final content = await versionInfoFile.readAsString();
          final data = Map<String, dynamic>.from(
            Uri.splitQueryString(content.replaceAll('=', ':')),
          );
          return ZipVersion.fromMap(data);
        }
      }

      return null;
    } catch (e) {
      AppLogger.debug('No existing version found for $routeId v$version: $e', tag: 'ZipManager');
      return null;
    }
  }

  /// Salva informações da versão
  Future<void> _saveVersionInfo(ZipVersion version) async {
    try {
      final versionInfoFile = File(path.join(version.extractedPath, '.version_info.json'));
      final content = version.toMap().entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      await versionInfoFile.writeAsString(content);
    } catch (e) {
      AppLogger.warning('Failed to save version info: $e', tag: 'ZipManager');
    }
  }

  /// Obtém diretório de ZIPs
  Future<Directory> _getZipDirectory(String routeId) async {
    final appDir = await getApplicationSupportDirectory();
    final zipDir = Directory(path.join(appDir.path, 'offline_zips', routeId));
    
    if (!await zipDir.exists()) {
      await zipDir.create(recursive: true);
    }
    
    return zipDir;
  }

  /// Obtém diretório base para arquivos extraídos
  Future<Directory> _getExtractedBaseDirectory(String routeId) async {
    final appDir = await getApplicationSupportDirectory();
    return Directory(path.join(appDir.path, 'offline_files', routeId));
  }

  /// Obtém diretório específico para versão extraída
  Future<Directory> _getExtractedDirectory(String routeId, String version) async {
    final baseDir = await _getExtractedBaseDirectory(routeId);
    final extractedDir = Directory(path.join(baseDir.path, 'v$version'));
    
    if (!await extractedDir.exists()) {
      await extractedDir.create(recursive: true);
    }
    
    return extractedDir;
  }

  /// Emite progresso para listeners
  void _emitProgress(String routeId, ZipProgress progress) {
    final controller = _progressControllers[routeId];
    if (controller != null && !controller.isClosed) {
      controller.add(progress);
    }
  }

  /// Stream de progresso para uma operação ZIP específica
  Stream<ZipProgress>? getProgressStream(String routeId) {
    return _progressControllers[routeId]?.stream;
  }

  /// Obtém versão atual de uma rota
  ZipVersion? getCurrentVersion(String routeId) {
    return _currentVersions[routeId];
  }

  /// Lista todas as versões disponíveis
  Future<List<ZipVersion>> getAvailableVersions(String routeId) async {
    try {
      final versions = <ZipVersion>[];
      final baseDir = await _getExtractedBaseDirectory(routeId);
      
      if (!await baseDir.exists()) return versions;

      final dirs = await baseDir
          .list()
          .where((entity) => entity is Directory)
          .cast<Directory>()
          .toList();

      for (final dir in dirs) {
        final versionInfoFile = File(path.join(dir.path, '.version_info.json'));
        if (await versionInfoFile.exists()) {
          try {
            final content = await versionInfoFile.readAsString();
            final data = Map<String, dynamic>.from(
              Uri.splitQueryString(content.replaceAll('=', ':')),
            );
            versions.add(ZipVersion.fromMap(data));
          } catch (e) {
            AppLogger.debug('Failed to parse version info: $e', tag: 'ZipManager');
          }
        }
      }

      return versions;
    } catch (e) {
      AppLogger.error('Failed to get available versions: $e', tag: 'ZipManager');
      return [];
    }
  }

  /// Remove completamente todos os dados de uma rota
  Future<bool> removeRouteData(String routeId) async {
    try {
      AppLogger.info('Removing all data for route: $routeId', tag: 'ZipManager');

      final zipDir = await _getZipDirectory(routeId);
      final extractedBaseDir = await _getExtractedBaseDirectory(routeId);

      // Remover ZIPs
      if (await zipDir.exists()) {
        await zipDir.delete(recursive: true);
      }

      // Remover arquivos extraídos
      if (await extractedBaseDir.exists()) {
        await extractedBaseDir.delete(recursive: true);
      }

      // Remover da memória
      _currentVersions.remove(routeId);

      AppLogger.info('Route data removed successfully: $routeId', tag: 'ZipManager');
      return true;

    } catch (e) {
      AppLogger.error('Failed to remove route data: $routeId -> $e', tag: 'ZipManager');
      return false;
    }
  }

  /// Obtém estatísticas do ZIP manager
  Map<String, dynamic> getStats() {
    return {
      'activeDownloads': _progressControllers.length,
      'cachedVersions': _currentVersions.length,
      'platform': kIsWeb ? 'web' : 'native',
      'supportsZip': !kIsWeb,
    };
  }

  /// Dispose - limpar recursos
  Future<void> dispose() async {
    // Fechar streams de progresso
    for (final controller in _progressControllers.values) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    _progressControllers.clear();
    _currentVersions.clear();
    
    _downloader.dispose(); // BackgroundDownloadService.dispose() returns void
  }
}

/// Resultado de extração
class ExtractionResult {
  final bool success;
  final String? error;
  final int? extractedFiles;

  const ExtractionResult({
    required this.success,
    this.error,
    this.extractedFiles,
  });
}