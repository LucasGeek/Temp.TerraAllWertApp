import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'cache_service.dart';
import '../upload/minio_upload_service.dart';
import '../sync/offline_sync_service.dart';
import '../logging/app_logger.dart';

/// Adaptador de cache específico para ImageCarouselPresentation  
/// Gerencia imagens, vídeos e recursos multimídia do carrossel
class ImageCarouselCacheAdapter {
  final CacheService _cacheService;
  final MinIOUploadService _uploadService;
  final OfflineSyncService _syncService;
  final ImagePicker _imagePicker = ImagePicker();

  ImageCarouselCacheAdapter({
    required CacheService cacheService,
    required MinIOUploadService uploadService,
    required OfflineSyncService syncService,
  }) : _cacheService = cacheService,
       _uploadService = uploadService,
       _syncService = syncService;

  /// Seleciona e armazena múltiplas imagens para o carrossel
  Future<List<String>> selectAndCacheCarouselImages({
    required String routeId,
    String? carouselId,
    bool allowMultiple = true,
  }) async {
    try {
      AppLogger.info('Starting carousel images selection for route: $routeId', tag: 'CarouselCache');
      
      List<String> cachedPaths = [];
      
      // Selecionar baseado na plataforma
      if (await _isWebPlatform()) {
        cachedPaths = await _selectCarouselImagesWeb(
          routeId: routeId, 
          carouselId: carouselId, 
          allowMultiple: allowMultiple,
        );
      } else {
        cachedPaths = await _selectCarouselImagesMobile(
          routeId: routeId, 
          carouselId: carouselId, 
          allowMultiple: allowMultiple,
        );
      }
      
      AppLogger.info('Selected and cached ${cachedPaths.length} carousel images', tag: 'CarouselCache');
      return cachedPaths;
      
    } catch (e) {
      AppLogger.error('Failed to select and cache carousel images: $e', tag: 'CarouselCache');
      rethrow;
    }
  }

  /// Seleciona imagens na web usando FilePicker
  Future<List<String>> _selectCarouselImagesWeb({
    required String routeId,
    String? carouselId,
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
          // Gerar ID único para imagem do carrossel
          final fileId = '${DateTime.now().millisecondsSinceEpoch}_carousel_${carouselId ?? 'default'}_${file.name.hashCode}';
          
          // Cache do arquivo
          final cachedInfo = await _cacheService.cacheFile(
            fileId: fileId,
            bytes: file.bytes!,
            originalPath: file.name!,
            type: 'carousel_image',
          );
          
          // Iniciar upload em background
          _startBackgroundUpload(
            fileId: fileId,
            contentType: _getContentType(file.name!),
            routeId: routeId,
            carouselId: carouselId,
            mediaType: 'image',
          );
          
          cachedPaths.add(cachedInfo.localPath);
          
        } catch (e) {
          AppLogger.error('Failed to cache carousel image ${file.name}: $e', tag: 'CarouselCache');
        }
      }
    }

    return cachedPaths;
  }

  /// Seleciona imagens no mobile usando ImagePicker
  Future<List<String>> _selectCarouselImagesMobile({
    required String routeId,
    String? carouselId,
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
        
        // Gerar ID único para imagem do carrossel
        final fileId = '${DateTime.now().millisecondsSinceEpoch}_carousel_${carouselId ?? 'default'}_${file.name.hashCode}';
        
        // Cache do arquivo
        final cachedInfo = await _cacheService.cacheFile(
          fileId: fileId,
          bytes: bytes,
          originalPath: file.path,
          type: 'carousel_image',
        );
        
        // Iniciar upload em background
        _startBackgroundUpload(
          fileId: fileId,
          contentType: _getContentType(file.name),
          routeId: routeId,
          carouselId: carouselId,
          mediaType: 'image',
        );
        
        cachedPaths.add(cachedInfo.localPath);
        
      } catch (e) {
        AppLogger.error('Failed to cache carousel image ${file.name}: $e', tag: 'CarouselCache');
      }
    }

    return cachedPaths;
  }

  /// Seleciona e armazena vídeo para o carrossel
  Future<String?> selectAndCacheCarouselVideo({
    required String routeId,
    String? carouselId,
  }) async {
    try {
      AppLogger.info('Starting carousel video selection for route: $routeId', tag: 'CarouselCache');
      
      String? cachedPath;
      
      // Selecionar baseado na plataforma
      if (await _isWebPlatform()) {
        cachedPath = await _selectCarouselVideoWeb(routeId: routeId, carouselId: carouselId);
      } else {
        cachedPath = await _selectCarouselVideoMobile(routeId: routeId, carouselId: carouselId);
      }
      
      if (cachedPath != null) {
        AppLogger.info('Carousel video cached successfully', tag: 'CarouselCache');
        return cachedPath;
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Failed to select and cache carousel video: $e', tag: 'CarouselCache');
      rethrow;
    }
  }

  /// Seleciona vídeo na web usando FilePicker
  Future<String?> _selectCarouselVideoWeb({
    required String routeId,
    String? carouselId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: true,
    );
    
    if (result?.files.isNotEmpty == true) {
      final file = result!.files.first;
      if (file.bytes != null && file.name != null) {
        try {
          final fileId = '${DateTime.now().millisecondsSinceEpoch}_carousel_video_${carouselId ?? 'default'}_${file.name.hashCode}';
          
          final cachedInfo = await _cacheService.cacheFile(
            fileId: fileId,
            bytes: file.bytes!,
            originalPath: file.name!,
            type: 'carousel_video',
          );
          
          _startBackgroundUpload(
            fileId: fileId,
            contentType: _getContentType(file.name!),
            routeId: routeId,
            carouselId: carouselId,
            mediaType: 'video',
          );
          
          return cachedInfo.localPath;
          
        } catch (e) {
          AppLogger.error('Failed to cache carousel video ${file.name}: $e', tag: 'CarouselCache');
          return null;
        }
      }
    }
    
    return null;
  }

  /// Seleciona vídeo no mobile usando ImagePicker
  Future<String?> _selectCarouselVideoMobile({
    required String routeId,
    String? carouselId,
  }) async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    
    if (video == null) {
      return null;
    }

    try {
      // Ler bytes do arquivo
      final bytes = await video.readAsBytes();
      
      // Gerar ID único para vídeo do carrossel
      final fileId = '${DateTime.now().millisecondsSinceEpoch}_carousel_video_${carouselId ?? 'default'}_${video.name.hashCode}';
      
      // Cache do arquivo
      final cachedInfo = await _cacheService.cacheFile(
        fileId: fileId,
        bytes: bytes,
        originalPath: video.path,
        type: 'carousel_video',
      );
      
      // Iniciar upload em background
      _startBackgroundUpload(
        fileId: fileId,
        contentType: _getContentType(video.name),
        routeId: routeId,
        carouselId: carouselId,
        mediaType: 'video',
      );
      
      return cachedInfo.localPath;
      
    } catch (e) {
      AppLogger.error('Failed to cache carousel video ${video.name}: $e', tag: 'CarouselCache');
      return null;
    }
  }

  /// Inicia upload em background
  void _startBackgroundUpload({
    required String fileId,
    required String contentType,
    required String routeId,
    String? carouselId,
    required String mediaType,
  }) {
    // TODO: Implementar upload em background quando API estiver pronta
    AppLogger.debug('TODO: Starting background upload for carousel file: $fileId', tag: 'CarouselCache');
    
    // Metadata específica para carrossel
    final metadata = {
      'type': 'carousel',
      'mediaType': mediaType,
      'routeId': routeId,
      if (carouselId != null) 'carouselId': carouselId,
      'uploadedAt': DateTime.now().toIso8601String(),
    };
    
    AppLogger.debug('Upload metadata: $metadata', tag: 'CarouselCache');
  }

  /// Obtém imagem do cache local
  Future<Uint8List?> getCachedCarouselImage(String localPath) async {
    return await _getCachedFile(localPath);
  }

  /// Obtém vídeo do cache local
  Future<Uint8List?> getCachedCarouselVideo(String localPath) async {
    return await _getCachedFile(localPath);
  }

  /// Método genérico para obter arquivos do cache
  Future<Uint8List?> _getCachedFile(String localPath) async {
    try {
      final fileId = _extractFileIdFromPath(localPath);
      if (fileId == null) {
        AppLogger.warning('Could not extract fileId from path: $localPath', tag: 'CarouselCache');
        return null;
      }
      
      return await _cacheService.getCachedFile(fileId);
    } catch (e) {
      AppLogger.error('Failed to get cached file $localPath: $e', tag: 'CarouselCache');
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
      AppLogger.error('Failed to remove cached file $localPath: $e', tag: 'CarouselCache');
      return false;
    }
  }

  /// Sincroniza todas as mídias do carrossel pendentes
  Future<void> syncPendingCarouselMedia() async {
    try {
      AppLogger.info('Starting sync of pending carousel media', tag: 'CarouselCache');
      await _uploadService.syncPendingFiles();
      AppLogger.info('Carousel media sync completed successfully', tag: 'CarouselCache');
    } catch (e) {
      AppLogger.error('Carousel media sync failed: $e', tag: 'CarouselCache');
    }
  }

  /// Converte paths locais para URLs da API ou ZIP offline
  Future<List<String>> convertCachedPathsToUrls({
    required List<String> localPaths,
    required String routeId,
  }) async {
    final urls = <String>[];
    
    for (final localPath in localPaths) {
      try {
        // Extrair fileId do path local
        final fileId = _extractFileIdFromPath(localPath);
        if (fileId == null) {
          AppLogger.warning('Could not extract fileId from path: $localPath', tag: 'CarouselCache');
          continue;
        }
        
        // Usar OfflineSyncService para obter URL correta baseada na plataforma
        final url = await _syncService.getFileUrl(
          fileId: fileId,
          routeId: routeId,
          originalFileName: localPath.split('/').last,
        );
        
        if (url != null) {
          urls.add(url);
        } else {
          AppLogger.warning('No URL available for file: $fileId', tag: 'CarouselCache');
        }
      } catch (e) {
        AppLogger.error('Failed to convert path to URL: $localPath -> $e', tag: 'CarouselCache');
      }
    }
    
    return urls;
  }

  /// Converte path único para URL da API ou ZIP offline
  Future<String?> convertCachedPathToUrl({
    required String localPath,
    required String routeId,
  }) async {
    final urls = await convertCachedPathsToUrls(
      localPaths: [localPath],
      routeId: routeId,
    );
    return urls.isNotEmpty ? urls.first : null;
  }

  /// Extrai fileId do path local
  String? _extractFileIdFromPath(String localPath) {
    try {
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
      case 'webm':
        return 'video/webm';
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

  /// Obtém estatísticas específicas do carrossel
  Map<String, dynamic> getCarouselCacheStats() {
    final stats = _cacheService.getCacheStats();
    
    // Filtrar estatísticas específicas do carrossel
    final allFiles = _cacheService.getAllCachedFiles();
    final carouselImages = allFiles.where((info) => info.type == 'carousel_image').length;
    final carouselVideos = allFiles.where((info) => info.type == 'carousel_video').length;
    
    return {
      ...stats,
      'carouselImages': carouselImages,
      'carouselVideos': carouselVideos,
      'carouselTotal': carouselImages + carouselVideos,
    };
  }

  /// Limpa cache do carrossel (usar com cuidado)
  Future<void> clearCarouselCache() async {
    // TODO: Implementar limpeza seletiva apenas do carrossel
    AppLogger.warning('Clearing all cache - consider selective cleanup', tag: 'CarouselCache');
    await _cacheService.clearCache();
  }
}