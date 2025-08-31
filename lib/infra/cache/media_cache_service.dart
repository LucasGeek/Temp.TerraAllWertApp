import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import '../platform/platform_service.dart';
import '../logging/app_logger.dart';

/// Service avançado para cache de mídia (imagens, vídeos, PDFs)
/// Funciona offline para mobile e desktop (ignora web)
class MediaCacheService {
  late Directory _cacheDir;
  late Directory _videosDir;
  late Directory _imagesDir;
  late Directory _documentsDir;
  
  static const String _metadataFileName = 'media_metadata.json';
  static const int _maxCacheAgeHours = 168; // 7 dias
  // static const int _maxCacheSizeMB = 500; // 500MB - Future use
  
  Map<String, MediaMetadata> _metadata = {};
  
  /// Inicializa o service de cache de mídia
  Future<void> initialize() async {
    try {
      // Para web, não faz cache local
      if (PlatformService.isWeb) {
        NetworkLogger.info('Web platform: media caching disabled');
        return;
      }
      
      NetworkLogger.info('Initializing media cache service for ${PlatformService.platformName}');
      
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(appDir.path, 'media_cache'));
      _imagesDir = Directory(path.join(_cacheDir.path, 'images'));
      _videosDir = Directory(path.join(_cacheDir.path, 'videos'));
      _documentsDir = Directory(path.join(_cacheDir.path, 'documents'));
      
      // Cria diretórios se não existirem
      await _ensureDirectoriesExist();
      
      // Carrega metadados existentes
      await _loadMetadata();
      
      // Limpa itens expirados
      await _cleanExpiredItems();
      
      NetworkLogger.info('Media cache service initialized successfully');
      NetworkLogger.debug('Cache directories: images=${_imagesDir.path}, videos=${_videosDir.path}, documents=${_documentsDir.path}');
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to initialize media cache service', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Baixa e cacheia uma imagem
  Future<File?> cacheImage(String url, {bool forceDownload = false}) async {
    if (PlatformService.isWeb) return null;
    
    try {
      final fileName = _generateFileName(url, MediaType.image);
      final file = File(path.join(_imagesDir.path, fileName));
      
      // Se já existe e não está expirado, retorna
      if (!forceDownload && await file.exists()) {
        final metadata = _metadata[url];
        if (metadata != null && !_isExpired(metadata)) {
          NetworkLogger.debug('Using cached image: $fileName');
          return file;
        }
      }
      
      // Baixa nova imagem
      NetworkLogger.info('Downloading and caching image: $url');
      final imageBytes = await _downloadFile(url);
      if (imageBytes == null) return null;
      
      await file.writeAsBytes(imageBytes);
      
      // Atualiza metadados
      _metadata[url] = MediaMetadata(
        url: url,
        fileName: fileName,
        type: MediaType.image,
        filePath: file.path,
        timestamp: DateTime.now(),
        size: imageBytes.length,
      );
      
      await _saveMetadata();
      
      NetworkLogger.info('Image cached successfully: $fileName (${imageBytes.length} bytes)');
      return file;
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to cache image: $url', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Baixa e cacheia um vídeo
  Future<File?> cacheVideo(String url, {bool forceDownload = false}) async {
    if (PlatformService.isWeb) return null;
    
    try {
      final fileName = _generateFileName(url, MediaType.video);
      final file = File(path.join(_videosDir.path, fileName));
      
      // Se já existe e não está expirado, retorna
      if (!forceDownload && await file.exists()) {
        final metadata = _metadata[url];
        if (metadata != null && !_isExpired(metadata)) {
          NetworkLogger.debug('Using cached video: $fileName');
          return file;
        }
      }
      
      // Baixa novo vídeo
      NetworkLogger.info('Downloading and caching video: $url');
      final videoBytes = await _downloadFile(url);
      if (videoBytes == null) return null;
      
      await file.writeAsBytes(videoBytes);
      
      // Atualiza metadados
      _metadata[url] = MediaMetadata(
        url: url,
        fileName: fileName,
        type: MediaType.video,
        filePath: file.path,
        timestamp: DateTime.now(),
        size: videoBytes.length,
      );
      
      await _saveMetadata();
      
      NetworkLogger.info('Video cached successfully: $fileName (${videoBytes.length} bytes)');
      return file;
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to cache video: $url', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Baixa e cacheia um documento (PDF, etc.)
  Future<File?> cacheDocument(String url, {bool forceDownload = false}) async {
    if (PlatformService.isWeb) return null;
    
    try {
      final fileName = _generateFileName(url, MediaType.document);
      final file = File(path.join(_documentsDir.path, fileName));
      
      // Se já existe e não está expirado, retorna
      if (!forceDownload && await file.exists()) {
        final metadata = _metadata[url];
        if (metadata != null && !_isExpired(metadata)) {
          NetworkLogger.debug('Using cached document: $fileName');
          return file;
        }
      }
      
      // Baixa novo documento
      NetworkLogger.info('Downloading and caching document: $url');
      final documentBytes = await _downloadFile(url);
      if (documentBytes == null) return null;
      
      await file.writeAsBytes(documentBytes);
      
      // Atualiza metadados
      _metadata[url] = MediaMetadata(
        url: url,
        fileName: fileName,
        type: MediaType.document,
        filePath: file.path,
        timestamp: DateTime.now(),
        size: documentBytes.length,
      );
      
      await _saveMetadata();
      
      NetworkLogger.info('Document cached successfully: $fileName (${documentBytes.length} bytes)');
      return file;
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to cache document: $url', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Obtém arquivo cacheado (qualquer tipo)
  Future<File?> getCachedFile(String url) async {
    if (PlatformService.isWeb) return null;
    
    final metadata = _metadata[url];
    if (metadata == null) return null;
    
    final file = File(metadata.filePath);
    if (!await file.exists()) {
      // Remove metadados se arquivo não existe
      _metadata.remove(url);
      await _saveMetadata();
      return null;
    }
    
    if (_isExpired(metadata)) {
      NetworkLogger.debug('Cached file expired: ${metadata.fileName}');
      return null;
    }
    
    return file;
  }
  
  /// Verifica se uma URL está cacheada
  bool isCached(String url) {
    if (PlatformService.isWeb) return false;
    return _metadata.containsKey(url) && !_isExpired(_metadata[url]!);
  }
  
  /// Pré-cache de múltiplas URLs (para usar quando online)
  Future<void> preCacheUrls(List<String> urls) async {
    if (PlatformService.isWeb) return;
    
    NetworkLogger.info('Pre-caching ${urls.length} URLs');
    
    int cached = 0;
    for (final url in urls) {
      try {
        File? cachedFile;
        
        if (_isImageUrl(url)) {
          cachedFile = await cacheImage(url);
        } else if (_isVideoUrl(url)) {
          cachedFile = await cacheVideo(url);
        } else if (_isDocumentUrl(url)) {
          cachedFile = await cacheDocument(url);
        }
        
        if (cachedFile != null) {
          cached++;
        }
      } catch (e) {
        NetworkLogger.warning('Failed to pre-cache URL: $url', error: e);
      }
    }
    
    NetworkLogger.info('Pre-caching completed: $cached/${urls.length} URLs cached successfully');
  }
  
  /// Download de arquivo via HTTP
  Future<Uint8List?> _downloadFile(String url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);
      
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final bytes = await _consolidateHttpClientResponseBytes(response);
        client.close();
        return bytes;
      } else {
        NetworkLogger.warning('HTTP ${response.statusCode} when downloading: $url');
        client.close();
        return null;
      }
    } catch (e, stackTrace) {
      NetworkLogger.error('Download failed: $url', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  /// Consolida bytes da resposta HTTP
  Future<Uint8List> _consolidateHttpClientResponseBytes(HttpClientResponse response) async {
    final completer = Completer<Uint8List>();
    final chunks = <List<int>>[];
    
    response.listen(
      (chunk) => chunks.add(chunk),
      onDone: () {
        final bytes = <int>[];
        for (final chunk in chunks) {
          bytes.addAll(chunk);
        }
        completer.complete(Uint8List.fromList(bytes));
      },
      onError: completer.completeError,
    );
    
    return completer.future;
  }
  
  /// Gera nome de arquivo baseado na URL
  String _generateFileName(String url, MediaType type) {
    final hash = sha256.convert(utf8.encode(url)).toString().substring(0, 16);
    final extension = _getFileExtension(url, type);
    return '$hash.$extension';
  }
  
  /// Obtém extensão do arquivo
  String _getFileExtension(String url, MediaType type) {
    // Primeiro, tenta extrair da URL
    final uri = Uri.parse(url);
    final pathExtension = path.extension(uri.path).toLowerCase();
    
    if (pathExtension.isNotEmpty) {
      return pathExtension.substring(1); // Remove o ponto
    }
    
    // Fallback baseado no tipo
    switch (type) {
      case MediaType.image:
        return 'jpg';
      case MediaType.video:
        return 'mp4';
      case MediaType.document:
        return 'pdf';
    }
  }
  
  /// Verifica se é URL de imagem
  bool _isImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains(RegExp(r'\.(jpg|jpeg|png|gif|webp|bmp)(\?|$)'));
  }
  
  /// Verifica se é URL de vídeo
  bool _isVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains(RegExp(r'\.(mp4|avi|mov|wmv|flv|webm|m4v)(\?|$)'));
  }
  
  /// Verifica se é URL de documento
  bool _isDocumentUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains(RegExp(r'\.(pdf|doc|docx|xls|xlsx|ppt|pptx)(\?|$)'));
  }
  
  /// Verifica se item está expirado
  bool _isExpired(MediaMetadata metadata) {
    final age = DateTime.now().difference(metadata.timestamp);
    return age.inHours > _maxCacheAgeHours;
  }
  
  /// Carrega metadados do disco
  Future<void> _loadMetadata() async {
    try {
      final metadataFile = File(path.join(_cacheDir.path, _metadataFileName));
      
      if (!await metadataFile.exists()) {
        _metadata = {};
        return;
      }
      
      final jsonString = await metadataFile.readAsString();
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      
      _metadata = jsonData.map((key, value) => MapEntry(
        key,
        MediaMetadata.fromJson(value),
      ));
      
      NetworkLogger.debug('Loaded ${_metadata.length} media metadata entries');
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to load media metadata', error: e, stackTrace: stackTrace);
      _metadata = {};
    }
  }
  
  /// Salva metadados no disco
  Future<void> _saveMetadata() async {
    try {
      final metadataFile = File(path.join(_cacheDir.path, _metadataFileName));
      
      final jsonData = _metadata.map((key, value) => MapEntry(
        key,
        value.toJson(),
      ));
      
      final jsonString = jsonEncode(jsonData);
      await metadataFile.writeAsString(jsonString);
      
      NetworkLogger.debug('Saved ${_metadata.length} media metadata entries');
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to save media metadata', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Garante que diretórios existem
  Future<void> _ensureDirectoriesExist() async {
    for (final dir in [_cacheDir, _imagesDir, _videosDir, _documentsDir]) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }
  
  /// Limpa itens expirados
  Future<void> _cleanExpiredItems() async {
    try {
      final expiredUrls = <String>[];
      
      for (final entry in _metadata.entries) {
        if (_isExpired(entry.value)) {
          expiredUrls.add(entry.key);
        }
      }
      
      for (final url in expiredUrls) {
        final metadata = _metadata[url]!;
        final file = File(metadata.filePath);
        
        if (await file.exists()) {
          await file.delete();
        }
        
        _metadata.remove(url);
      }
      
      if (expiredUrls.isNotEmpty) {
        await _saveMetadata();
        NetworkLogger.info('Cleaned ${expiredUrls.length} expired cache items');
      }
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to clean expired items', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Obtém estatísticas do cache
  Future<CacheStats> getCacheStats() async {
    if (PlatformService.isWeb) {
      return CacheStats(totalItems: 0, totalSize: 0, imagesCount: 0, videosCount: 0, documentsCount: 0);
    }
    
    int totalSize = 0;
    int imagesCount = 0;
    int videosCount = 0;
    int documentsCount = 0;
    
    for (final metadata in _metadata.values) {
      totalSize += metadata.size;
      
      switch (metadata.type) {
        case MediaType.image:
          imagesCount++;
          break;
        case MediaType.video:
          videosCount++;
          break;
        case MediaType.document:
          documentsCount++;
          break;
      }
    }
    
    return CacheStats(
      totalItems: _metadata.length,
      totalSize: totalSize,
      imagesCount: imagesCount,
      videosCount: videosCount,
      documentsCount: documentsCount,
    );
  }
  
  /// Limpa todo o cache
  Future<void> clearCache() async {
    if (PlatformService.isWeb) return;
    
    try {
      if (await _cacheDir.exists()) {
        await _cacheDir.delete(recursive: true);
        await _ensureDirectoriesExist();
      }
      
      _metadata.clear();
      await _saveMetadata();
      
      NetworkLogger.info('Media cache cleared completely');
    } catch (e, stackTrace) {
      NetworkLogger.error('Failed to clear media cache', error: e, stackTrace: stackTrace);
    }
  }
}

/// Metadados de arquivo cacheado
class MediaMetadata {
  final String url;
  final String fileName;
  final MediaType type;
  final String filePath;
  final DateTime timestamp;
  final int size;
  
  MediaMetadata({
    required this.url,
    required this.fileName,
    required this.type,
    required this.filePath,
    required this.timestamp,
    required this.size,
  });
  
  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      url: json['url'],
      fileName: json['fileName'],
      type: MediaType.values[json['type']],
      filePath: json['filePath'],
      timestamp: DateTime.parse(json['timestamp']),
      size: json['size'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'fileName': fileName,
      'type': type.index,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      'size': size,
    };
  }
}

/// Tipos de mídia suportados
enum MediaType { image, video, document }

/// Estatísticas do cache
class CacheStats {
  final int totalItems;
  final int totalSize;
  final int imagesCount;
  final int videosCount;
  final int documentsCount;
  
  CacheStats({
    required this.totalItems,
    required this.totalSize,
    required this.imagesCount,
    required this.videosCount,
    required this.documentsCount,
  });
  
  String get totalSizeFormatted {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

final mediaCacheServiceProvider = Provider<MediaCacheService>((ref) {
  return MediaCacheService();
});

final mediaCacheServiceInitProvider = FutureProvider<void>((ref) async {
  final mediaCacheService = ref.watch(mediaCacheServiceProvider);
  await mediaCacheService.initialize();
});