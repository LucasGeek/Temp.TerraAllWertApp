import 'package:freezed_annotation/freezed_annotation.dart';
import 'map_pin.dart';

part 'interactive_map_data.freezed.dart';
part 'interactive_map_data.g.dart';

@freezed
abstract class InteractiveMapData with _$InteractiveMapData {
  const factory InteractiveMapData({
    required String id,
    required String routeId,
    String? backgroundImageUrl,
    required List<MapPin> pins,
    String? videoUrl,
    String? videoPath,
    String? videoTitle,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _InteractiveMapData;

  factory InteractiveMapData.fromJson(Map<String, dynamic> json) => 
      _$InteractiveMapDataFromJson(json);
}