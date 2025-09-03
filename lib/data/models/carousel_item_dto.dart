import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/carousel_item.dart';

part 'carousel_item_dto.freezed.dart';
part 'carousel_item_dto.g.dart';

@freezed
abstract class CarouselItemDto with _$CarouselItemDto {
  const factory CarouselItemDto({
    required String id,
    required String menuId,
    required String itemType,
    String? backgroundFileId,
    @Default(0) int position,
    String? title,
    String? subtitle,
    String? ctaText,
    String? ctaUrl,
    Map<String, dynamic>? mapData,
    @Default(5) int preloadPriority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _CarouselItemDto;

  factory CarouselItemDto.fromJson(Map<String, dynamic> json) => _$CarouselItemDtoFromJson(json);
}

extension CarouselItemDtoMapper on CarouselItemDto {
  CarouselItem toEntity(String localId) {
    return CarouselItem(
      localId: localId,
      remoteId: id,
      menuLocalId: menuId,
      itemType: _parseItemType(itemType),
      backgroundFileLocalId: backgroundFileId,
      position: position,
      title: title,
      subtitle: subtitle,
      ctaText: ctaText,
      ctaUrl: ctaUrl,
      mapData: mapData,
      preloadPriority: preloadPriority,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
  
  CarouselItemType _parseItemType(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'banner':
        return CarouselItemType.banner;
      case 'video':
        return CarouselItemType.video;
      case 'map':
        return CarouselItemType.map;
      case 'card':
        return CarouselItemType.card;
      default:
        return CarouselItemType.custom;
    }
  }
}

extension CarouselItemMapper on CarouselItem {
  CarouselItemDto toDto() {
    return CarouselItemDto(
      id: remoteId ?? localId,
      menuId: menuLocalId,
      itemType: itemType.name,
      backgroundFileId: backgroundFileLocalId,
      position: position,
      title: title,
      subtitle: subtitle,
      ctaText: ctaText,
      ctaUrl: ctaUrl,
      mapData: mapData,
      preloadPriority: preloadPriority,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}