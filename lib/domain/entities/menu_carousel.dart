import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_carousel.freezed.dart';
part 'menu_carousel.g.dart';

@freezed
abstract class MenuCarousel with _$MenuCarousel {
  const factory MenuCarousel({
    required String localId,
    String? remoteId,
    required String menuLocalId,
    String? promotionalVideoLocalId,
    @Default(true) bool autoplay,
    @Default(5000) int autoplayInterval,
    @Default(true) bool showIndicators,
    @Default(true) bool showControls,
    @Default('slide') String transitionType,
    @Default(true) bool enableSwipe,
    @Default(true) bool loop,
    @Default(2) int preloadItemsCount,
    @Default(true) bool cacheVideoThumbnails,
    String? offlineFallbackImageLocalId,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(1) int syncVersion,
    @Default(false) bool isModified,
    DateTime? lastModifiedAt,
  }) = _MenuCarousel;

  factory MenuCarousel.fromJson(Map<String, dynamic> json) => _$MenuCarouselFromJson(json);
}