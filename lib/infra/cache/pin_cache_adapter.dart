import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'cache_service.dart';
import 'models/cache_metadata.dart';
import '../upload/minio_upload_service.dart';
import '../logging/app_logger.dart';

/// Adaptador de cache específico para PinMapPresentation
/// Gerencia o ciclo completo: seleção -> cache -> upload -> metadados
class PinCacheAdapter {
  final CacheService _cacheService;
  final MinIOUploadService _uploadService;
  final ImagePicker _imagePicker = ImagePicker();

  PinCacheAdapter({
    required CacheService cacheService,
    required MinIOUploadService uploadService,
  }) : _cacheService = cacheService,
       _uploadService = uploadService;

  /// Seleciona e processa imagens para pins
  Future<List<String>> selectAndCacheImages({
    required String routeId,
    String? pinId,
    bool allowMultiple = true,
  }) async {
    try {
      AppLogger.info('Starting image selection for route: $routeId', tag: 'PinCache');
      
      List<String> cachedPaths = [];
      
      // Selecionar imagens baseado na plataforma
      if (await _isWebPlatform()) {
        cachedPaths = await _selectImagesWeb(routeId: routeId, pinId: pinId, allowMultiple: allowMultiple);
      } else {
        cachedPaths = await _selectImagesMobile(routeId: routeId, pinId: pinId, allowMultiple: allowMultiple);
      }
      
      AppLogger.info('Selected and cached ${cachedPaths.length} images', tag: 'PinCache');
      return cachedPaths;
      
    } catch (e) {
      AppLogger.error('Failed to select and cache images: $e', tag: 'PinCache');
      rethrow;
    }
  }

  /// Seleciona imagens na web usando FilePicker
  Future<List<String>> _selectImagesWeb({
    required String routeId,
    String? pinId,
    bool allowMultiple = true,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: allowMultiple,
      withData: true, // Necessário para web
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    List<String> cachedPaths = [];

    for (final file in result.files) {
      if (file.bytes != null && file.name != null) {
        try {
          // Gerar ID único
          final fileId = '${DateTime.now().millisecondsSinceEpoch}_${file.name.hashCode}';
          
          // Cache do arquivo
          final cachedInfo = await _cacheService.cacheFile(
            fileId: fileId,
            bytes: file.bytes!,
            originalPath: file.name!,
            type: 'image',
          );
          
          // Iniciar upload em background
          _startBackgroundUpload(
            fileId: fileId,
            contentType: _getContentType(file.name!),
            routeId: routeId,
            pinId: pinId,
          );
          
          cachedPaths.add(cachedInfo.localPath);
          
        } catch (e) {
          AppLogger.error('Failed to cache file ${file.name}: $e', tag: 'PinCache');
        }
      }
    }

    return cachedPaths;
  }

  /// Seleciona imagens no mobile usando ImagePicker
  Future<List<String>> _selectImagesMobile({
    required String routeId,
    String? pinId,
    bool allowMultiple = true,
  }) async {
    List<XFile> selectedFiles = [];
    
    if (allowMultiple) {
      selectedFiles = await _imagePicker.pickMultiImage();
    } else {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        selectedFiles = [file];
      }
    }

    if (selectedFiles.isEmpty) {
      return [];
    }

    List<String> cachedPaths = [];

    for (final file in selectedFiles) {
      try {
        // Ler bytes do arquivo
        final bytes = await file.readAsBytes();
        
        // Gerar ID único
        final fileId = '${DateTime.now().millisecondsSinceEpoch}_${file.name.hashCode}';
        
        // Cache do arquivo
        final cachedInfo = await _cacheService.cacheFile(
          fileId: fileId,
          bytes: bytes,
          originalPath: file.path,
          type: 'image',
        );
        
        // Iniciar upload em background
        _startBackgroundUpload(
          fileId: fileId,
          contentType: _getContentType(file.name),
          routeId: routeId,
          pinId: pinId,
        );
        
        cachedPaths.add(cachedInfo.localPath);
        
      } catch (e) {
        AppLogger.error('Failed to cache file ${file.name}: $e', tag: 'PinCache');
      }
    }

    return cachedPaths;
  }

  /// Seleciona e processa vídeo para pins
  Future<String?> selectAndCacheVideo({
    required String routeId,
    String? pinId,
  }) async {
    try {
      AppLogger.info('Starting video selection for route: $routeId', tag: 'PinCache');
      
      XFile? videoFile;
      
      if (await _isWebPlatform()) {
        // Web: usar FilePicker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: false,
          withData: true,
        );
        
        if (result?.files.isNotEmpty == true) {
          final file = result!.files.first;
          if (file.bytes != null && file.name != null) {
            // Criar XFile mock para compatibilidade
            // TODO: Implementar lógica específica para web se necessário
            AppLogger.debug('Video selected on web: ${file.name}', tag: 'PinCache');
          }
        }
      } else {
        // Mobile: usar ImagePicker
        videoFile = await _imagePicker.pickVideo(source: ImageSource.gallery);
      }
      
      if (videoFile == null) {
        return null;
      }
      
      // Processar arquivo de vídeo
      final bytes = await videoFile.readAsBytes();
      final fileId = '${DateTime.now().millisecondsSinceEpoch}_${videoFile.name.hashCode}';
      
      // Cache do arquivo
      final cachedInfo = await _cacheService.cacheFile(
        fileId: fileId,
        bytes: bytes,
        originalPath: videoFile.path,
        type: 'video',
      );
      
      // Iniciar upload em background
      _startBackgroundUpload(
        fileId: fileId,
        contentType: _getContentType(videoFile.name),
        routeId: routeId,
        pinId: pinId,
      );
      
      AppLogger.info('Video cached successfully: ${cachedInfo.localPath}', tag: 'PinCache');
      return cachedInfo.localPath;
      
    } catch (e) {
      AppLogger.error('Failed to select and cache video: $e', tag: 'PinCache');
      rethrow;
    }
  }

  /// Inicia upload em background
  void _startBackgroundUpload({
    required String fileId,
    required String contentType,
    required String routeId,
    String? pinId,
  }) {
    // TODO: Implementar upload em background quando API estiver pronta
    AppLogger.debug('TODO: Starting background upload for file: $fileId', tag: 'PinCache');
    
    // Código para quando a API estiver implementada:
    /*
    _uploadService.uploadFileComplete(
      fileBytes: cachedBytes,
      originalPath: originalPath,
      fileType: type,
      contentType: contentType,
      routeId: routeId,
      pinId: pinId,
      onProgress: (progress) {
        AppLogger.debug('Upload progress for $fileId: ${progress.progress}', tag: 'PinCache');
      },
    ).catchError((e) {
      AppLogger.error('Background upload failed for $fileId: $e', tag: 'PinCache');
    });
    */
  }

  /// Obtém arquivo do cache local
  Future<Uint8List?> getCachedFile(String localPath) async {
    try {
      // Extrair fileId do path local
      final fileId = _extractFileIdFromPath(localPath);
      if (fileId == null) {
        AppLogger.warning('Could not extract fileId from path: $localPath', tag: 'PinCache');
        return null;
      }
      
      return await _cacheService.getCachedFile(fileId);
    } catch (e) {
      AppLogger.error('Failed to get cached file $localPath: $e', tag: 'PinCache');
      return null;
    }
  }

  /// Remove arquivo do cache
  Future<bool> removeCachedFile(String localPath) async {
    try {
      final fileId = _extractFileIdFromPath(localPath);
      if (fileId == null) {
        return false;
      }
      
      return await _cacheService.removeCachedFile(fileId);
    } catch (e) {
      AppLogger.error('Failed to remove cached file $localPath: $e', tag: 'PinCache');
      return false;
    }
  }

  /// Sincroniza todos os arquivos pendentes
  Future<void> syncPendingFiles() async {
    try {
      AppLogger.info('Starting sync of pending files', tag: 'PinCache');
      await _uploadService.syncPendingFiles();
      AppLogger.info('Sync completed successfully', tag: 'PinCache');
    } catch (e) {
      AppLogger.error('Sync failed: $e', tag: 'PinCache');
    }
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() {
    return _cacheService.getCacheStats();
  }

  /// Limpa cache (usar com cuidado)
  Future<void> clearCache() async {
    await _cacheService.clearCache();
    AppLogger.info('Cache cleared', tag: 'PinCache');
  }

  /// Extrai fileId do path local
  String? _extractFileIdFromPath(String localPath) {
    try {
      // Assumindo que o nome do arquivo é o fileId + extensão
      final fileName = localPath.split('/').last;
      final fileId = fileName.split('.').first;
      return fileId;
    } catch (e) {
      return null;
    }
  }

  /// Determina o content type baseado na extensão
  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  /// Verifica se está rodando na web
  Future<bool> _isWebPlatform() async {
    // TODO: Implementar detecção correta de plataforma
    // Por enquanto, assumir que não é web para desenvolvimento
    return false;
  }

  /// Converte paths locais para URLs que podem ser usadas no PinMapPresentation
  List<String> convertCachedPathsToUrls(List<String> localPaths) {
    // Para desenvolvimento, retornar os paths locais
    // TODO: Quando MinIO estiver funcionando, converter para URLs públicas ou blob URLs
    return localPaths.map((path) {
      // Por enquanto, usar file:// URLs para desenvolvimento local
      return 'file://$path';
    }).toList();
  }

  /// Força sincronização de um arquivo específico
  Future<String?> forceSyncFile(String localPath) async {
    try {
      final fileId = _extractFileIdFromPath(localPath);
      if (fileId == null) {
        return null;
      }

      final fileInfo = _cacheService.getCachedFileInfo(fileId);
      if (fileInfo == null) {
        return null;
      }

      // TODO: Implementar sync individual quando API estiver pronta
      AppLogger.info('TODO: Force sync file: $fileId', tag: 'PinCache');
      
      // Código para quando API estiver implementada:
      /*
      final bytes = await _cacheService.getCachedFile(fileId);
      if (bytes == null) return null;
      
      final minioPath = await _uploadService.uploadFileComplete(
        fileBytes: bytes,
        originalPath: fileInfo.originalPath,
        fileType: fileInfo.type,
        contentType: _getContentType(fileInfo.originalPath),
        routeId: routeId, // Precisaria ser passado como parâmetro
      );
      
      return minioPath;
      */
      
      return null;
    } catch (e) {
      AppLogger.error('Failed to force sync file $localPath: $e', tag: 'PinCache');
      return null;
    }
  }
}