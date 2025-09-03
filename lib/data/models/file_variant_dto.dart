import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_variant_dto.freezed.dart';
part 'file_variant_dto.g.dart';

@freezed
abstract class FileVariantDto with _$FileVariantDto {
  const factory FileVariantDto({
    required String id,
    required String fileId,
    required String variantName,
    required String url,
    @Default(0) int width,
    @Default(0) int height,
    @Default(0) int fileSize,
    required String mimeType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FileVariantDto;

  factory FileVariantDto.fromJson(Map<String, dynamic> json) => _$FileVariantDtoFromJson(json);
}