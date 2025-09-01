import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/pin_content_type.dart';

part 'map_pin.freezed.dart';
part 'map_pin.g.dart';

/// Entidade para pins no mapa interativo
@freezed
abstract class MapPin with _$MapPin {
  const factory MapPin({
    required String id,
    required String title,
    required String description,
    required double positionX, // Posição X relativa (0.0 a 1.0)
    required double positionY, // Posição Y relativa (0.0 a 1.0)
    required PinContentType contentType,
    required List<String> imageUrls, // URLs das imagens (path local ou URL)
    @Default([]) List<String> imagePaths, // Paths locais das imagens para modo offline
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MapPin;

  factory MapPin.fromJson(Map<String, dynamic> json) => _$MapPinFromJson(json);
}

/// Entidade para dados do mapa interativo
@freezed
abstract class InteractiveMapData with _$InteractiveMapData {
  const factory InteractiveMapData({
    required String id,
    required String routeId, // ID da rota associada
    String? backgroundImageUrl,
    String? backgroundImagePath, // Path local da imagem de fundo
    String? videoUrl,
    String? videoPath, // Path local do vídeo
    String? videoTitle, // Título do vídeo
    @Default([]) List<MapPin> pins,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _InteractiveMapData;

  factory InteractiveMapData.fromJson(Map<String, dynamic> json) => _$InteractiveMapDataFromJson(json);
}