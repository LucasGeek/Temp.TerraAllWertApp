import 'package:freezed_annotation/freezed_annotation.dart';
import 'image_pin.dart';

part 'gallery_image.freezed.dart';
part 'gallery_image.g.dart';

@freezed
class GalleryImage with _$GalleryImage {
  const factory GalleryImage({
    required String id,
    required String apartmentId,
    required String url,
    String? thumbnailUrl,
    String? title,
    String? description,
    required int order,
    List<ImagePin>? pins,
    String? mimeType,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isSynced,
  }) = _GalleryImage;

  factory GalleryImage.fromJson(Map<String, dynamic> json) => _$GalleryImageFromJson(json);
}