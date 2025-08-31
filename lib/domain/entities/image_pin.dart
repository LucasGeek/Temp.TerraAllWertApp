import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_pin.freezed.dart';
part 'image_pin.g.dart';

@freezed
abstract class ImagePin with _$ImagePin {
  const factory ImagePin({
    required String id,
    required String imageId,
    required double x,
    required double y,
    required String title,
    String? description,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isSynced,
  }) = _ImagePin;

  factory ImagePin.fromJson(Map<String, dynamic> json) => _$ImagePinFromJson(json);
}