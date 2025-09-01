import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/map_type.dart';

part 'carousel_data.freezed.dart';
part 'carousel_data.g.dart';

/// Entidade para caixa de texto personalizada
@freezed
abstract class TextBox with _$TextBox {
  const factory TextBox({
    required String id,
    required String text,
    required double fontSize,
    required int fontColor, // Color.value para serialização
    required int backgroundColor, // Color.value para serialização
    @Default(0.5) double positionX, // Posição X relativa (0.0 a 1.0)
    @Default(0.5) double positionY, // Posição Y relativa (0.0 a 1.0)
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TextBox;

  factory TextBox.fromJson(Map<String, dynamic> json) => _$TextBoxFromJson(json);
}

/// Entidade para configuração de mapa
@freezed
abstract class MapConfig with _$MapConfig {
  const factory MapConfig({
    required String id,
    required double latitude,
    required double longitude,
    required MapType mapType,
    @Default(15.0) double zoom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MapConfig;

  factory MapConfig.fromJson(Map<String, dynamic> json) => _$MapConfigFromJson(json);
}

/// Entidade principal para dados do carrossel
@freezed
abstract class CarouselData with _$CarouselData {
  const factory CarouselData({
    required String id,
    required String routeId, // ID da rota associada
    @Default([]) List<String> imageUrls,
    @Default([]) List<String> imagePaths, // Paths locais para modo offline
    String? videoUrl,
    String? videoPath, // Path local do vídeo
    String? videoTitle, // Título do vídeo
    TextBox? textBox, // Apenas 1 caixa de texto
    MapConfig? mapConfig, // Apenas 1 mapa
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CarouselData;

  factory CarouselData.fromJson(Map<String, dynamic> json) => _$CarouselDataFromJson(json);
}