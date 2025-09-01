import 'package:freezed_annotation/freezed_annotation.dart';

part 'cache_metadata.freezed.dart';
part 'cache_metadata.g.dart';

/// Metadados de sincronização do cache
@freezed
abstract class CacheMetadata with _$CacheMetadata {
  const factory CacheMetadata({
    required String version,
    required DateTime lastSync,
    required Map<String, DateTime> itemTimestamps,
    required int totalFiles,
    required int totalSize,
  }) = _CacheMetadata;

  factory CacheMetadata.fromJson(Map<String, dynamic> json) => _$CacheMetadataFromJson(json);
}

/// Informações de um arquivo no cache
@freezed
abstract class CachedFileInfo with _$CachedFileInfo {
  const factory CachedFileInfo({
    required String id,
    required String originalPath,
    required String localPath,
    required String type, // 'image', 'video', 'document'
    required DateTime cachedAt,
    required DateTime lastModified,
    required int size,
    required String checksum,
    String? minioPath,
    DateTime? uploadedAt,
    bool? isUploaded,
  }) = _CachedFileInfo;

  factory CachedFileInfo.fromJson(Map<String, dynamic> json) => _$CachedFileInfoFromJson(json);
}

/// Solicitação de URL assinada para upload
@freezed
abstract class SignedUrlRequest with _$SignedUrlRequest {
  const factory SignedUrlRequest({
    required String fileId,
    required String fileName,
    required String fileType,
    required String contentType,
    required int fileSize,
    String? routeId,
    String? pinId,
  }) = _SignedUrlRequest;

  factory SignedUrlRequest.fromJson(Map<String, dynamic> json) => _$SignedUrlRequestFromJson(json);
}

/// Resposta da URL assinada
@freezed
abstract class SignedUrlResponse with _$SignedUrlResponse {
  const factory SignedUrlResponse({
    required String uploadUrl,
    required String minioPath,
    required String fileId,
    required DateTime expiresAt,
    required Map<String, String> headers,
  }) = _SignedUrlResponse;

  factory SignedUrlResponse.fromJson(Map<String, dynamic> json) => _$SignedUrlResponseFromJson(json);
}

/// Status de upload de arquivo
enum UploadStatus {
  pending,
  uploading,
  completed,
  failed,
  cancelled,
}

/// Informações de progresso de upload
@freezed
abstract class UploadProgress with _$UploadProgress {
  const factory UploadProgress({
    required String fileId,
    required UploadStatus status,
    required double progress, // 0.0 to 1.0
    required int bytesUploaded,
    required int totalBytes,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _UploadProgress;

  factory UploadProgress.fromJson(Map<String, dynamic> json) => _$UploadProgressFromJson(json);
}