import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/menu_carousel.dart';

part 'menu_carousel_dto.freezed.dart';
part 'menu_carousel_dto.g.dart';

@freezed
abstract class MenuCarouselDto with _$MenuCarouselDto {
  const factory MenuCarouselDto({
    required String id,
    required String menuId,
    @Default(0) int position,
    @Default(true) bool isActive,
    @Default(5) int autoplaySeconds,
    @Default(true) bool showIndicators,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MenuCarouselDto;

  factory MenuCarouselDto.fromJson(Map<String, dynamic> json) => 
      _$MenuCarouselDtoFromJson(json);
}

extension MenuCarouselDtoMapper on MenuCarouselDto {
  MenuCarousel toEntity(String localId) {
    return MenuCarousel(
      localId: localId,
      remoteId: id,
      menuLocalId: menuId,
      autoplayInterval: autoplaySeconds * 1000, // Convert to milliseconds
      showIndicators: showIndicators,
      createdAt: createdAt ?? DateTime.now(),
      lastModifiedAt: updatedAt,
    );
  }
}

extension MenuCarouselEntityMapper on MenuCarousel {
  MenuCarouselDto toDto() {
    return MenuCarouselDto(
      id: remoteId ?? localId,
      menuId: menuLocalId,
      position: 0, // Default position
      isActive: true, // Default active
      autoplaySeconds: (autoplayInterval / 1000).round(), // Convert from milliseconds
      showIndicators: showIndicators,
      createdAt: createdAt,
      updatedAt: lastModifiedAt,
    );
  }
}