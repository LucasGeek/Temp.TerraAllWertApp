import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'cache_service.dart';
import '../upload/minio_upload_service.dart';
import '../sync/offline_sync_service.dart';
import '../logging/app_logger.dart';

/// Adaptador de cache específico para FloorPlanPresentation
/// Gerencia plantas de pavimento, imagens de andares e documentos técnicos
class FloorPlanCacheAdapter {
  final CacheService _cacheService;
  final MinIOUploadService _uploadService;
  final OfflineSyncService _syncService;
  final ImagePicker _imagePicker = ImagePicker();

  FloorPlanCacheAdapter({
    required CacheService cacheService,
    required MinIOUploadService uploadService,
    required OfflineSyncService syncService,
  }) : _cacheService = cacheService,
       _uploadService = uploadService,
       _syncService = syncService;

  /// Seleciona e armazena plantas de pavimento
  Future<String?> selectAndCacheFloorPlan({
    required String routeId,
    required String floorId,
  }) async {
    try {
      AppLogger.info('Starting floor plan selection for floor: $floorId', tag: 'FloorPlanCache');
      
      String? cachedPath;
      
      // Selecionar baseado na plataforma
      if (await _isWebPlatform()) {
        cachedPath = await _selectFloorPlanWeb(routeId: routeId, floorId: floorId);
      } else {
        cachedPath = await _selectFloorPlanMobile(routeId: routeId, floorId: floorId);
      }
      
      if (cachedPath != null) {
        AppLogger.info('Floor plan cached successfully', tag: 'FloorPlanCache');
        return cachedPath;
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Failed to select and cache floor plan: $e', tag: 'FloorPlanCache');
      rethrow;
    }
  }

  /// Seleciona planta na web usando FilePicker
  Future<String?> _selectFloorPlanWeb({
    required String routeId,
    required String floorId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // Necessário para web
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    if (file.bytes != null) {
      try {
        // Gerar ID único para planta
        final fileId = '${DateTime.now().millisecondsSinceEpoch}_floor_${floorId}_${file.name.hashCode}';
        
        // Cache do arquivo
        final cachedInfo = await _cacheService.cacheFile(
          fileId: fileId,
          bytes: file.bytes!,
          originalPath: file.name,
          type: 'floorplan',
        );
        
        // Iniciar upload em background
        _startBackgroundUpload(
          fileId: fileId,
          contentType: _getContentType(file.name),
          routeId: routeId,
          floorId: floorId,
        );
        
        return cachedInfo.localPath;
        
      } catch (e) {
        AppLogger.error('Failed to cache floor plan ${file.name}: $e', tag: 'FloorPlanCache');
        return null;
      }
    }
    
    return null;
  }

  /// Seleciona planta no mobile usando ImagePicker
  Future<String?> _selectFloorPlanMobile({
    required String routeId,
    required String floorId,
  }) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90, // Alta qualidade para plantas técnicas
    );

    if (image == null) {
      return null;
    }

    try {
      // Ler bytes do arquivo
      final bytes = await image.readAsBytes();
      
      // Gerar ID único para planta
      final fileId = '${DateTime.now().millisecondsSinceEpoch}_floor_${floorId}_${image.name.hashCode}';
      
      // Cache do arquivo
      final cachedInfo = await _cacheService.cacheFile(
        fileId: fileId,
        bytes: bytes,
        originalPath: image.path,
        type: 'floorplan',
      );
      
      // Iniciar upload em background
      _startBackgroundUpload(
        fileId: fileId,
        contentType: _getContentType(image.name),
        routeId: routeId,
        floorId: floorId,
      );
      
      return cachedInfo.localPath;
      
    } catch (e) {
      AppLogger.error('Failed to cache floor plan ${image.name}: $e', tag: 'FloorPlanCache');
      return null;
    }
  }

  /// Seleciona múltiplas imagens de referência para plantas
  Future<List<String>> selectAndCacheReferenceImages({
    required String routeId,
    required String floorId,
    bool allowMultiple = true,
  }) async {
    try {
      AppLogger.info('Starting reference images selection for floor: $floorId', tag: 'FloorPlanCache');
      
      List<String> cachedPaths = [];
      
      // Selecionar baseado na plataforma
      if (await _isWebPlatform()) {
        cachedPaths = await _selectReferenceImagesWeb(
          routeId: routeId, 
          floorId: floorId, 
          allowMultiple: allowMultiple,
        );
      } else {
        cachedPaths = await _selectReferenceImagesMobile(
          routeId: routeId, 
          floorId: floorId, 
          allowMultiple: allowMultiple,
        );
      }
      
      AppLogger.info('Selected and cached ${cachedPaths.length} reference images', tag: 'FloorPlanCache');
      return cachedPaths;
      
    } catch (e) {
      AppLogger.error('Failed to select and cache reference images: $e', tag: 'FloorPlanCache');
      rethrow;
    }
  }

  /// Seleciona imagens de referência na web
  Future<List<String>> _selectReferenceImagesWeb({
    required String routeId,
    required String floorId,
    bool allowMultiple = true,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: allowMultiple,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    List<String> cachedPaths = [];

    for (final file in result.files) {
      if (file.bytes != null) {
        try {
          final fileId = '${DateTime.now().millisecondsSinceEpoch}_ref_${floorId}_${file.name.hashCode}';
          
          final cachedInfo = await _cacheService.cacheFile(
            fileId: fileId,
            bytes: file.bytes!,
            originalPath: file.name,
            type: 'reference',
          );
          
          _startBackgroundUpload(
            fileId: fileId,
            contentType: _getContentType(file.name),
            routeId: routeId,
            floorId: floorId,
          );
          
          cachedPaths.add(cachedInfo.localPath);
          
        } catch (e) {
          AppLogger.error('Failed to cache reference image ${file.name}: $e', tag: 'FloorPlanCache');
        }
      }
    }

    return cachedPaths;
  }

  /// Seleciona imagens de referência no mobile
  Future<List<String>> _selectReferenceImagesMobile({
    required String routeId,
    required String floorId,
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
        final bytes = await file.readAsBytes();
        final fileId = '${DateTime.now().millisecondsSinceEpoch}_ref_${floorId}_${file.name.hashCode}';
        
        final cachedInfo = await _cacheService.cacheFile(
          fileId: fileId,
          bytes: bytes,
          originalPath: file.path,
          type: 'reference',
        );
        
        _startBackgroundUpload(
          fileId: fileId,
          contentType: _getContentType(file.name),
          routeId: routeId,
          floorId: floorId,
        );
        
        cachedPaths.add(cachedInfo.localPath);
        
      } catch (e) {
        AppLogger.error('Failed to cache reference image ${file.name}: $e', tag: 'FloorPlanCache');
      }
    }

    return cachedPaths;
  }

  /// Inicia upload em background
  void _startBackgroundUpload({
    required String fileId,
    required String contentType,
    required String routeId,
    String? floorId,
  }) {
    // TODO: Implementar upload em background quando API estiver pronta
    AppLogger.debug('TODO: Starting background upload for floor plan file: $fileId', tag: 'FloorPlanCache');
    
    // Metadata específica para plantas
    final metadata = {
      'type': 'floorplan',
      'routeId': routeId,
      if (floorId != null) 'floorId': floorId,
      'uploadedAt': DateTime.now().toIso8601String(),
    };
    
    AppLogger.debug('Upload metadata: $metadata', tag: 'FloorPlanCache');
  }

  /// Obtém arquivo do cache local
  Future<Uint8List?> getCachedFloorPlan(String localPath) async {
    return await _getCachedFile(localPath);
  }

  /// Obtém arquivo de referência do cache
  Future<Uint8List?> getCachedReferenceImage(String localPath) async {
    return await _getCachedFile(localPath);
  }

  /// Método genérico para obter arquivos do cache
  Future<Uint8List?> _getCachedFile(String localPath) async {
    try {
      final fileId = _extractFileIdFromPath(localPath);
      if (fileId == null) {
        AppLogger.warning('Could not extract fileId from path: $localPath', tag: 'FloorPlanCache');
        return null;
      }
      
      return await _cacheService.getCachedFile(fileId);
    } catch (e) {
      AppLogger.error('Failed to get cached file $localPath: $e', tag: 'FloorPlanCache');
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
      AppLogger.error('Failed to remove cached file $localPath: $e', tag: 'FloorPlanCache');
      return false;
    }
  }

  /// Sincroniza todas as plantas pendentes
  Future<void> syncPendingFloorPlans() async {
    try {
      AppLogger.info('Starting sync of pending floor plans', tag: 'FloorPlanCache');
      await _uploadService.syncPendingFiles();
      AppLogger.info('Floor plan sync completed successfully', tag: 'FloorPlanCache');
    } catch (e) {
      AppLogger.error('Floor plan sync failed: $e', tag: 'FloorPlanCache');
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
          AppLogger.warning('Could not extract fileId from path: $localPath', tag: 'FloorPlanCache');
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
          AppLogger.warning('No URL available for file: $fileId', tag: 'FloorPlanCache');
        }
      } catch (e) {
        AppLogger.error('Failed to convert path to URL: $localPath -> $e', tag: 'FloorPlanCache');
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
      case 'pdf':
        return 'application/pdf';
      case 'dwg':
        return 'application/dwg';
      case 'dxf':
        return 'application/dxf';
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

  /// Obtém estatísticas específicas de plantas
  Map<String, dynamic> getFloorPlanCacheStats() {
    final stats = _cacheService.getCacheStats();
    
    // Filtrar estatísticas específicas de plantas
    final allFiles = _cacheService.getAllCachedFiles();
    final floorPlanFiles = allFiles.where((info) => info.type == 'floorplan').length;
    final referenceFiles = allFiles.where((info) => info.type == 'reference').length;
    
    return {
      ...stats,
      'floorPlanFiles': floorPlanFiles,
      'referenceFiles': referenceFiles,
    };
  }

  /// Limpa cache de plantas (usar com cuidado)
  Future<void> clearFloorPlanCache() async {
    // TODO: Implementar limpeza seletiva apenas de plantas
    AppLogger.warning('Clearing all cache - consider selective cleanup', tag: 'FloorPlanCache');
    await _cacheService.clearCache();
  }
}