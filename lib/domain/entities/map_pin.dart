import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_pin.freezed.dart';
part 'map_pin.g.dart';

/// Tipos de conteúdo que um pin pode conter
enum PinContentType {
  singleImage('Imagem única'),
  imageGallery('Galeria de imagens'),
  textWithImages('Texto com imagens');

  const PinContentType(this.displayName);
  final String displayName;
}

@freezed
abstract class MapPin with _$MapPin {
  const factory MapPin({
    required String id,
    required String title,
    required String description,
    required double positionX,
    required double positionY,
    required PinContentType contentType,
    required List<String> imageUrls,
    @Default([]) List<String> imagePaths,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _MapPin;

  factory MapPin.fromJson(Map<String, dynamic> json) => _$MapPinFromJson(json);
}