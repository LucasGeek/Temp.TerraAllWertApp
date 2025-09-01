import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../cache/cache_service.dart';
import '../cache/models/cache_metadata.dart';
import '../graphql/graphql_client.dart';
import '../logging/app_logger.dart';

/// Serviço de upload para MinIO com URLs assinadas
class MinIOUploadService {
  final GraphQLClientService _graphqlClient;
  final CacheService _cacheService;
  final Dio _dio;
  
  // Stream controllers para progresso de upload
  final Map<String, StreamController<UploadProgress>> _progressControllers = {};
  
  MinIOUploadService({
    required GraphQLClientService graphqlClient,
    required CacheService cacheService,
  }) : _graphqlClient = graphqlClient,
       _cacheService = cacheService,
       _dio = Dio();

  /// Obtém URL assinada para upload
  Future<SignedUrlResponse> getSignedUploadUrl({
    required String fileId,
    required String fileName,
    required String fileType,
    required String contentType,
    required int fileSize,
    String? routeId,
    String? pinId,
  }) async {
    try {
      // TODO: Implementar mutation GraphQL para obter URL assinada
      // Esta é a mutation que deve ser implementada na API:
      /*
      mutation GetSignedUploadUrl($input: SignedUrlRequestInput!) {
        getSignedUploadUrl(input: $input) {
          uploadUrl
          minioPath
          fileId
          expiresAt
          headers {
            key
            value
          }
        }
      }
      */
      
      AppLogger.debug('Requesting signed upload URL for file: $fileId', tag: 'MinIO');
      
      final request = SignedUrlRequest(
        fileId: fileId,
        fileName: fileName,
        fileType: fileType,
        contentType: contentType,
        fileSize: fileSize,
        routeId: routeId,
        pinId: pinId,
      );

      // TODO: Substituir por chamada GraphQL real quando API estiver implementada
      // Por enquanto, simular resposta para desenvolvimento
      await Future.delayed(Duration(milliseconds: 500)); // Simular latência
      
      final mockResponse = SignedUrlResponse(
        uploadUrl: 'https://mock-minio.example.com/upload/signed-url',
        minioPath: 'pins/$routeId/$fileId/${path.basename(fileName)}',
        fileId: fileId,
        expiresAt: DateTime.now().add(Duration(hours: 1)),
        headers: {
          'Content-Type': contentType,
          'x-amz-acl': 'private',
        },
      );
      
      AppLogger.info('Got signed upload URL for $fileId: ${mockResponse.minioPath}', tag: 'MinIO');
      return mockResponse;
      
    } catch (e) {
      AppLogger.error('Failed to get signed upload URL for $fileId: $e', tag: 'MinIO');
      rethrow;
    }
  }

  /// Faz upload de arquivo para MinIO
  Future<bool> uploadFile({
    required String fileId,
    required SignedUrlResponse signedUrl,
    Function(UploadProgress)? onProgress,
  }) async {
    try {
      AppLogger.info('Starting upload for file: $fileId', tag: 'MinIO');
      
      // Obter arquivo do cache
      final fileBytes = await _cacheService.getCachedFile(fileId);
      if (fileBytes == null) {
        throw Exception('File not found in cache: $fileId');
      }
      
      final fileInfo = _cacheService.getCachedFileInfo(fileId);
      if (fileInfo == null) {
        throw Exception('File info not found in cache: $fileId');
      }
      
      // Criar stream de progresso
      final progressController = StreamController<UploadProgress>.broadcast();
      _progressControllers[fileId] = progressController;
      
      // Configurar listener de progresso
      if (onProgress != null) {
        progressController.stream.listen(onProgress);
      }
      
      // Preparar dados para upload
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: path.basename(fileInfo.originalPath),
        ),
      });
      
      // Preparar headers
      final headers = <String, String>{
        ...signedUrl.headers,
      };
      
      var uploadProgress = UploadProgress(
        fileId: fileId,
        status: UploadStatus.uploading,
        progress: 0.0,
        bytesUploaded: 0,
        totalBytes: fileBytes.length,
        startedAt: DateTime.now(),
      );
      
      progressController.add(uploadProgress);
      
      try {
        // TODO: Fazer upload real para MinIO quando URL assinada estiver funcionando
        // Por enquanto, simular upload para desenvolvimento
        
        AppLogger.debug('Simulating upload for file: $fileId', tag: 'MinIO');
        
        // Simular progresso de upload
        for (int i = 0; i <= 10; i++) {
          await Future.delayed(Duration(milliseconds: 200));
          uploadProgress = uploadProgress.copyWith(
            progress: i / 10.0,
            bytesUploaded: (fileBytes.length * i / 10.0).round(),
          );
          progressController.add(uploadProgress);
        }
        
        /*
        // Código real de upload (descomentado quando API estiver pronta):
        final response = await _dio.post(
          signedUrl.uploadUrl,
          data: formData,
          options: Options(
            headers: headers,
            validateStatus: (status) => status! < 400,
          ),
          onSendProgress: (sent, total) {
            uploadProgress = uploadProgress.copyWith(
              progress: sent / total,
              bytesUploaded: sent,
              totalBytes: total,
            );
            progressController.add(uploadProgress);
          },
        );
        
        if (response.statusCode != 200) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'Upload failed with status: ${response.statusCode}',
          );
        }
        */
        
        // Marcar como completado
        uploadProgress = uploadProgress.copyWith(
          status: UploadStatus.completed,
          progress: 1.0,
          bytesUploaded: fileBytes.length,
          completedAt: DateTime.now(),
        );
        progressController.add(uploadProgress);
        
        // Marcar arquivo como enviado no cache
        await _cacheService.markAsUploaded(fileId, signedUrl.minioPath);
        
        AppLogger.info('Upload completed successfully for file: $fileId', tag: 'MinIO');
        return true;
        
      } catch (e) {
        uploadProgress = uploadProgress.copyWith(
          status: UploadStatus.failed,
          error: e.toString(),
          completedAt: DateTime.now(),
        );
        progressController.add(uploadProgress);
        rethrow;
      }
      
    } catch (e) {
      AppLogger.error('Upload failed for file $fileId: $e', tag: 'MinIO');
      return false;
    } finally {
      // Limpar stream controller
      _progressControllers.remove(fileId)?.close();
    }
  }

  /// Upload de arquivo completo (cache + MinIO)
  Future<String?> uploadFileComplete({
    required Uint8List fileBytes,
    required String originalPath,
    required String fileType,
    required String contentType,
    String? routeId,
    String? pinId,
    Function(UploadProgress)? onProgress,
  }) async {
    try {
      // Gerar ID único para o arquivo
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      
      AppLogger.info('Starting complete upload process for file: $originalPath', tag: 'MinIO');
      
      // 1. Salvar no cache local
      await _cacheService.cacheFile(
        fileId: fileId,
        bytes: fileBytes,
        originalPath: originalPath,
        type: fileType,
      );
      
      // 2. Obter URL assinada
      final signedUrl = await getSignedUploadUrl(
        fileId: fileId,
        fileName: path.basename(originalPath),
        fileType: fileType,
        contentType: contentType,
        fileSize: fileBytes.length,
        routeId: routeId,
        pinId: pinId,
      );
      
      // 3. Fazer upload
      final success = await uploadFile(
        fileId: fileId,
        signedUrl: signedUrl,
        onProgress: onProgress,
      );
      
      if (success) {
        AppLogger.info('Complete upload process finished for: $originalPath -> ${signedUrl.minioPath}', tag: 'MinIO');
        return signedUrl.minioPath;
      } else {
        throw Exception('Upload process failed');
      }
      
    } catch (e) {
      AppLogger.error('Complete upload process failed for $originalPath: $e', tag: 'MinIO');
      rethrow;
    }
  }

  /// Obtém progresso de upload de um arquivo
  Stream<UploadProgress>? getUploadProgress(String fileId) {
    return _progressControllers[fileId]?.stream;
  }

  /// Cancela upload de um arquivo
  Future<void> cancelUpload(String fileId) async {
    final controller = _progressControllers[fileId];
    if (controller != null) {
      final cancelProgress = UploadProgress(
        fileId: fileId,
        status: UploadStatus.cancelled,
        progress: 0.0,
        bytesUploaded: 0,
        totalBytes: 0,
        completedAt: DateTime.now(),
      );
      controller.add(cancelProgress);
      controller.close();
      _progressControllers.remove(fileId);
      
      AppLogger.info('Upload cancelled for file: $fileId', tag: 'MinIO');
    }
  }

  /// Sincroniza arquivos pendentes
  Future<void> syncPendingFiles() async {
    try {
      final pendingFiles = _cacheService.getFilesNeedingSync();
      
      if (pendingFiles.isEmpty) {
        AppLogger.info('No files need sync', tag: 'MinIO');
        return;
      }
      
      AppLogger.info('Starting sync for ${pendingFiles.length} pending files', tag: 'MinIO');
      
      for (final fileInfo in pendingFiles) {
        try {
          // Obter URL assinada
          final signedUrl = await getSignedUploadUrl(
            fileId: fileInfo.id,
            fileName: path.basename(fileInfo.originalPath),
            fileType: fileInfo.type,
            contentType: _getContentType(fileInfo.originalPath),
            fileSize: fileInfo.size,
          );
          
          // Fazer upload
          await uploadFile(
            fileId: fileInfo.id,
            signedUrl: signedUrl,
          );
          
          AppLogger.info('Synced file: ${fileInfo.id}', tag: 'MinIO');
          
        } catch (e) {
          AppLogger.error('Failed to sync file ${fileInfo.id}: $e', tag: 'MinIO');
          // Continue with next file
        }
      }
      
      AppLogger.info('Sync process completed', tag: 'MinIO');
      
    } catch (e) {
      AppLogger.error('Sync process failed: $e', tag: 'MinIO');
    }
  }

  /// Obtém content type baseado na extensão do arquivo
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Libera recursos
  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
  }
}