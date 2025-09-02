import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_types.freezed.dart';
part 'menu_types.g.dart';

/// Enum para tipo de menu
enum TipoMenu {
  @JsonValue('Padrao')
  padrao('Padrao'),
  @JsonValue('Com Submenu')
  comSubmenu('Com Submenu');

  final String value;
  const TipoMenu(this.value);
}

/// Enum para tipo de tela
enum TipoTela {
  @JsonValue('Pins')
  pins('Pins'),
  @JsonValue('Pavimento')
  pavimento('Pavimento'),
  @JsonValue('Padrao')
  padrao('Padrao');

  final String value;
  const TipoTela(this.value);
}

/// Entidade Menu atualizada
@freezed
abstract class Menu with _$Menu {
  const factory Menu({
    required String id,
    required String title,
    String? description,
    String? icon,
    String? route,
    @Default(true) bool isActive,
    @Default(TipoMenu.padrao) TipoMenu tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
    DateTime? createdAt,
    DateTime? updatedAt,
    
    // Relações opcionais
    Menu? menuPai,
    @Default([]) List<Menu> submenus,
    
    // Dados específicos do tipo de tela (opcionais)
    MenuFloor? menuFloor,
    MenuCarousel? menuCarousel,
    MenuPin? menuPin,
  }) = _Menu;

  factory Menu.fromJson(Map<String, dynamic> json) => _$MenuFromJson(json);
}

/// Configuração para Menu tipo Pavimento
@freezed
abstract class MenuFloor with _$MenuFloor {
  const factory MenuFloor({
    required String id,
    required String menuId,
    Map<String, dynamic>? layoutJson,
    @Default(1.0) double zoomDefault,
    @Default(true) bool allowZoom,
    @Default(false) bool showGrid,
    @Default(10) int gridSize,
    String? backgroundColor,
    @Default(1) int floorCount,
    @Default(1) int defaultFloor,
    @Default([]) List<String> floorLabels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MenuFloor;

  factory MenuFloor.fromJson(Map<String, dynamic> json) => _$MenuFloorFromJson(json);
}

/// Configuração para Menu tipo Carrossel
@freezed
abstract class MenuCarousel with _$MenuCarousel {
  const factory MenuCarousel({
    required String id,
    required String menuId,
    @Default([]) List<CarouselImage> images,
    @Default(5000) int transitionTime,
    @Default('fade') String transitionType,
    @Default(true) bool autoPlay,
    @Default(true) bool showIndicators,
    @Default(true) bool showArrows,
    @Default(true) bool allowSwipe,
    @Default(true) bool infiniteLoop,
    @Default('16:9') String aspectRatio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MenuCarousel;

  factory MenuCarousel.fromJson(Map<String, dynamic> json) => _$MenuCarouselFromJson(json);
}

/// Imagem do carrossel
@freezed
abstract class CarouselImage with _$CarouselImage {
  const factory CarouselImage({
    required String url,
    String? title,
    String? description,
    String? link,
    int? order,
  }) = _CarouselImage;

  factory CarouselImage.fromJson(Map<String, dynamic> json) => _$CarouselImageFromJson(json);
}

/// Configuração para Menu tipo Pins
@freezed
abstract class MenuPin with _$MenuPin {
  const factory MenuPin({
    required String id,
    required String menuId,
    Map<String, dynamic>? mapConfig,
    @Default([]) List<PinData> pinData,
    String? backgroundImageUrl,
    Map<String, dynamic>? mapBounds,
    @Default(1.0) double initialZoom,
    @Default(0.5) double minZoom,
    @Default(3.0) double maxZoom,
    @Default(false) bool enableClustering,
    @Default(50) int clusterRadius,
    String? pinIconDefault,
    @Default(true) bool showPinLabels,
    @Default(true) bool enableSearch,
    @Default(true) bool enableFilters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MenuPin;

  factory MenuPin.fromJson(Map<String, dynamic> json) => _$MenuPinFromJson(json);
}

/// Dados de um pin no mapa
@freezed
abstract class PinData with _$PinData {
  const factory PinData({
    required String id,
    required double latitude,
    required double longitude,
    String? title,
    String? description,
    String? icon,
    String? color,
    Map<String, dynamic>? customData,
    @Default(true) bool isVisible,
  }) = _PinData;

  factory PinData.fromJson(Map<String, dynamic> json) => _$PinDataFromJson(json);
}

