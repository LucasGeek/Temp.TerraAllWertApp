import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/cached_file.dart';

part 'file_dto.freezed.dart';
part 'file_dto.g.dart';

@freezed
abstract class FileDto with _$FileDto {
  const factory FileDto({
    required String id,
    required String fileName,
    required String originalUrl,
    @Default(0) int fileSize,
    required String mimeType,
    String? checksum,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FileDto;

  factory FileDto.fromJson(Map<String, dynamic> json) => _$FileDtoFromJson(json);
}

extension FileDtoMapper on FileDto {
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
  FileDto toDto() {
    return FileDto(
      id: remoteId ?? localId,
      fileName: originalName,
      originalUrl: remoteUrl,
      fileSize: fileSizeBytes,
      mimeType: mimeType,
      createdAt: createdAt,
    );
  }
}