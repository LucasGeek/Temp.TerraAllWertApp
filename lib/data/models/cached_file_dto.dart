import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/cached_file.dart';

part 'cached_file_dto.freezed.dart';
part 'cached_file_dto.g.dart';

@freezed
abstract class CachedFileDto with _$CachedFileDto {
  const factory CachedFileDto({
    required String id,
    required String fileName,
    required String originalUrl,
    @Default(0) int fileSize,
    required String mimeType,
    String? checksum,
    @Default(false) bool isDownloaded,
    DateTime? downloadedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _CachedFileDto;

  factory CachedFileDto.fromJson(Map<String, dynamic> json) => _$CachedFileDtoFromJson(json);
}

extension CachedFileDtoMapper on CachedFileDto {
  CachedFile toEntity(String localId) {
    return CachedFile(
      localId: localId,
      remoteId: id,
      fileType: _getFileTypeFromMimeType(mimeType),
      mimeType: mimeType,
      originalName: fileName,
      cachePath: null,
      remoteUrl: originalUrl,
      fileSizeBytes: fileSize,
      expiresAt: expiresAt,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
  
  String _getFileTypeFromMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType == 'application/pdf') return 'document';
    if (mimeType.startsWith('text/')) return 'document';
    return 'file';
  }
}

extension CachedFileMapper on CachedFile {
  CachedFileDto toDto() {
    return CachedFileDto(
      id: remoteId ?? localId,
      fileName: originalName,
      originalUrl: remoteUrl,
      fileSize: fileSizeBytes,
      mimeType: mimeType,
      isDownloaded: isDownloaded,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }
}