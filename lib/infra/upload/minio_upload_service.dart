import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;

import '../cache/cache_service.dart';
import '../cache/models/cache_metadata.dart';
import '../logging/app_logger.dart';
import '../graphql/graphql_client.dart';
import '../graphql/mutations/file_upload_mutations.dart';
import 'package:graphql/client.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';

/// Serviço de upload para MinIO com URLs assinadas
class MinIOUploadService {
  final CacheService _cacheService;
  final GraphQLClientService _graphqlClient;
  final Dio _dio = Dio();
  
  // Stream controllers para progresso de upload
  final Map<String, StreamController<UploadProgress>> _progressControllers = {};
  
  MinIOUploadService({
    required CacheService cacheService,
    required GraphQLClientService graphqlClient,
  }) : _cacheService = cacheService,
       _graphqlClient = graphqlClient;

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
      AppLogger.debug('Requesting signed upload URL for file: $fileId', tag: 'MinIO');
      
      // Real GraphQL API integration
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(getSignedUploadUrlMutation),
          variables: {
            'input': {
              'fileName': fileName,
              'fileType': fileType,
              'contentType': contentType,
              'routeId': routeId,
              if (pinId != null) 'context': {
                'pinId': pinId,
              },
            }
          },
        ),
      );
      
      if (result.hasException) {
        AppLogger.error('GraphQL error getting signed upload URL: ${result.exception}', tag: 'MinIO');
        throw Exception('Failed to get signed upload URL: ${result.exception}');
      }
      
      final data = result.data?['getSignedUploadUrl'];
      if (data == null) {
        throw Exception('No data returned from getSignedUploadUrl mutation');
      }
      
      final response = SignedUrlResponse(
        uploadUrl: data['uploadUrl'] as String,
        minioPath: data['minioPath'] as String,
        fileId: data['fileId'] as String,
        expiresAt: DateTime.parse(data['expiresAt'] as String),
        headers: (data['headers'] as List?)?.fold<Map<String, String>>({}, (map, header) {
          map[header['key'] as String] = header['value'] as String;
          return map;
        }) ?? {},
      );
      
      AppLogger.info('Got signed upload URL for $fileId: ${response.minioPath}', tag: 'MinIO');
      return response;
      
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
        AppLogger.debug('Starting real upload for file: $fileId', tag: 'MinIO');
        
        // Merge headers from signed URL response
        final headers = Map<String, String>.from(signedUrl.headers);
        
        // Perform the actual upload to MinIO
        final response = await _dio.put(
          signedUrl.uploadUrl,
          data: fileBytes,
          options: Options(
            headers: headers,
            validateStatus: (status) => status != null && status < 400,
            responseType: ResponseType.plain,
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
        
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'Upload failed with status: ${response.statusCode}',
          );
        }
        
        // Calculate file checksum
        final checksum = _calculateSHA256(fileBytes);
        
        // Confirm upload with the API
        await _confirmFileUpload(
          fileId: signedUrl.fileId,
          minioPath: signedUrl.minioPath,
          checksum: checksum,
          fileSize: fileBytes.length,
        );
        
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

  /// Sincroniza arquivos pendentes com batch operations
  Future<void> syncPendingFiles({
    Function(BatchUploadProgress)? onProgress,
  }) async {
    try {
      final pendingFiles = _cacheService.getFilesNeedingSync();
      
      if (pendingFiles.isEmpty) {
        AppLogger.info('No files need sync', tag: 'MinIO');
        return;
      }
      
      AppLogger.info('Starting batch sync for ${pendingFiles.length} pending files', tag: 'MinIO');
      
      // Usar batch operations
      await uploadMultipleFiles(
        files: pendingFiles,
        onProgress: onProgress,
      );
      
      AppLogger.info('Batch sync process completed', tag: 'MinIO');
      
    } catch (e) {
      AppLogger.error('Batch sync process failed: $e', tag: 'MinIO');
    }
  }
  
  /// Upload múltiplos arquivos com concorrência controlada
  Future<List<UploadResult>> uploadMultipleFiles({
    required List<CachedFileInfo> files,
    int? maxConcurrency,
    Function(BatchUploadProgress)? onProgress,
  }) async {
    if (files.isEmpty) {
      return [];
    }
    
    // Determinar concorrência baseado na plataforma
    final concurrent = maxConcurrency ?? _getPlatformConcurrency();
    
    AppLogger.info('Starting batch upload of ${files.length} files with $concurrent concurrent uploads', tag: 'MinIO');
    
    final results = <UploadResult>[];
    final fileProgress = <String, UploadProgress>{};
    int completedCount = 0;
    int failedCount = 0;
    
    // Dividir em batches para processar
    final batches = _createBatches(files, concurrent);
    
    for (final batch in batches) {
      // Processar batch em paralelo
      final batchFutures = batch.map((fileInfo) async {
        try {
          // Progress tracking individual
          fileProgress[fileInfo.id] = UploadProgress(
            fileId: fileInfo.id,
            progress: 0.0,
            status: UploadStatus.pending,
            bytesUploaded: 0,
            totalBytes: fileInfo.size,
          );
          
          // Obter URL assinada
          final signedUrl = await getSignedUploadUrl(
            fileId: fileInfo.id,
            fileName: path.basename(fileInfo.originalPath),
            fileType: fileInfo.type,
            contentType: _getContentType(fileInfo.originalPath),
            fileSize: fileInfo.size,
          );
          
          // Upload com progress tracking
          await uploadFile(
            fileId: fileInfo.id,
            signedUrl: signedUrl,
            onProgress: (progress) {
              fileProgress[fileInfo.id] = progress;
              _notifyBatchProgress(
                onProgress,
                files.length,
                completedCount,
                failedCount,
                fileProgress,
              );
            },
          );
          
          completedCount++;
          fileProgress[fileInfo.id] = UploadProgress(
            fileId: fileInfo.id,
            progress: 1.0,
            status: UploadStatus.completed,
            bytesUploaded: fileInfo.size,
            totalBytes: fileInfo.size,
          );
          
          AppLogger.debug('Uploaded file ${fileInfo.id} in batch', tag: 'MinIO');
          
          return UploadResult(
            fileId: fileInfo.id,
            success: true,
          );
          
        } catch (e) {
          failedCount++;
          fileProgress[fileInfo.id] = UploadProgress(
            fileId: fileInfo.id,
            progress: 0.0,
            status: UploadStatus.failed,
            bytesUploaded: 0,
            totalBytes: fileInfo.size,
            error: e.toString(),
          );
          
          AppLogger.error('Failed to upload file ${fileInfo.id} in batch: $e', tag: 'MinIO');
          
          return UploadResult(
            fileId: fileInfo.id,
            success: false,
            error: e.toString(),
          );
        }
      }).toList();
      
      // Aguardar batch completar
      final batchResults = await Future.wait(batchFutures);
      results.addAll(batchResults);
      
      // Notificar progresso do batch
      _notifyBatchProgress(
        onProgress,
        files.length,
        completedCount,
        failedCount,
        fileProgress,
      );
    }
    
    AppLogger.info('Batch upload completed: $completedCount success, $failedCount failed', tag: 'MinIO');
    
    return results;
  }
  
  /// Cria batches para processamento concorrente
  List<List<CachedFileInfo>> _createBatches(List<CachedFileInfo> files, int batchSize) {
    final batches = <List<CachedFileInfo>>[];
    for (var i = 0; i < files.length; i += batchSize) {
      final end = (i + batchSize < files.length) ? i + batchSize : files.length;
      batches.add(files.sublist(i, end));
    }
    return batches;
  }
  
  /// Obtém limite de concorrência baseado na plataforma
  int _getPlatformConcurrency() {
    // TODO: Usar PlatformCapabilities quando implementado
    if (kIsWeb) {
      return 3; // Web: limite de 3 uploads simultâneos
    } else if (Platform.isAndroid || Platform.isIOS) {
      return 5; // Mobile: limite de 5 uploads simultâneos
    } else {
      return 10; // Desktop: limite de 10 uploads simultâneos
    }
  }
  
  /// Notifica progresso do batch upload
  void _notifyBatchProgress(
    Function(BatchUploadProgress)? onProgress,
    int totalFiles,
    int completedFiles,
    int failedFiles,
    Map<String, UploadProgress> fileProgress,
  ) {
    if (onProgress == null) return;
    
    final overallProgress = totalFiles > 0 
        ? (completedFiles + failedFiles) / totalFiles 
        : 0.0;
    
    onProgress(BatchUploadProgress(
      totalFiles: totalFiles,
      completedFiles: completedFiles,
      failedFiles: failedFiles,
      overallProgress: overallProgress,
      fileProgress: Map.from(fileProgress),
    ));
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

  /// Calcula checksum SHA-256 de um array de bytes
  String _calculateSHA256(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Confirma upload com a API
  Future<void> _confirmFileUpload({
    required String fileId,
    required String minioPath,
    required String checksum,
    required int fileSize,
  }) async {
    try {
      AppLogger.debug('Confirming file upload with API: $fileId', tag: 'MinIO');
      
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(confirmFileUploadMutation),
          variables: {
            'input': {
              'fileId': fileId,
              'minioPath': minioPath,
              'checksum': checksum,
              'fileSize': fileSize,
            }
          },
        ),
      );
      
      if (result.hasException) {
        AppLogger.error('GraphQL error confirming upload: ${result.exception}', tag: 'MinIO');
        throw Exception('Failed to confirm file upload: ${result.exception}');
      }
      
      final data = result.data?['confirmFileUpload'];
      if (data == null || !(data['success'] as bool? ?? false)) {
        throw Exception('Upload confirmation failed: ${data?['error']}');
      }
      
      AppLogger.info('Upload confirmed successfully for file: $fileId', tag: 'MinIO');
      
    } catch (e) {
      AppLogger.error('Failed to confirm upload for $fileId: $e', tag: 'MinIO');
      rethrow;
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