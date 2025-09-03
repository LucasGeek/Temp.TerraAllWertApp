import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_pin.freezed.dart';
part 'menu_pin.g.dart';

@freezed
abstract class MenuPin with _$MenuPin {
  const factory MenuPin({
    required String localId,
    String? remoteId,
    required String menuLocalId,
    String? backgroundFileLocalId,
    String? promotionalVideoLocalId,
    @Default(true) bool enableZoom,
    @Default(true) bool enablePan,
    @Default(0.5) double minZoom,
    @Default(3.0) double maxZoom,
    @Default(1.0) double initialZoom,
    @Default(true) bool showPinLabels,
    @Default(false) bool clusterNearbyPins,
    @Default(false) bool cacheAllPinImages,
    @Default(true) bool enableOfflineInteraction,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(1) int syncVersion,
    @Default(false) bool isModified,
    DateTime? lastModifiedAt,
  }) = _MenuPin;

  factory MenuPin.fromJson(Map<String, dynamic> json) => _$MenuPinFromJson(json);
}