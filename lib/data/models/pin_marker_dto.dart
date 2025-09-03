import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/pin_marker.dart';

part 'pin_marker_dto.freezed.dart';
part 'pin_marker_dto.g.dart';

@freezed
abstract class PinMarkerDto with _$PinMarkerDto {
  const factory PinMarkerDto({
    required String id,
    required String menuId,
    required String title,
    String? description,
    required double positionX,
    required double positionY,
    @Default('default') String iconType,
    @Default('#FF0000') String iconColor,
    @Default('info') String actionType,
    Map<String, dynamic>? actionData,
    @Default(true) bool isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _PinMarkerDto;

  factory PinMarkerDto.fromJson(Map<String, dynamic> json) => _$PinMarkerDtoFromJson(json);
}

extension PinMarkerDtoMapper on PinMarkerDto {
  PinMarker toEntity(String localId) {
    return PinMarker(
      localId: localId,
      remoteId: id,
      menuLocalId: menuId,
      title: title,
      description: description,
      positionX: positionX,
      positionY: positionY,
      x: positionX,
      y: positionY,
      iconType: _parseIconType(iconType),
      iconColor: iconColor,
      actionType: _parseActionType(actionType),
      actionData: actionData,
      isVisible: isVisible,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  PinIconType _parseIconType(String type) {
    switch (type) {
      case 'default':
        return PinIconType.defaultIcon;
      case 'marker':
        return PinIconType.marker;
      case 'star':
        return PinIconType.star;
      case 'heart':
        return PinIconType.heart;
      case 'custom':
        return PinIconType.custom;
      default:
        return PinIconType.defaultIcon;
    }
  }

  PinActionType _parseActionType(String type) {
    switch (type) {
      case 'info':
        return PinActionType.info;
      case 'link':
        return PinActionType.link;
      case 'navigation':
        return PinActionType.navigation;
      case 'custom':
        return PinActionType.custom;
      default:
        return PinActionType.info;
    }
  }
}

extension PinMarkerMapper on PinMarker {
  PinMarkerDto toDto() {
    return PinMarkerDto(
      id: remoteId ?? localId,
      menuId: menuLocalId,
      title: title,
      description: description,
      positionX: positionX,
      positionY: positionY,
      iconType: iconType.name,
      iconColor: iconColor,
      actionType: actionType.name,
      actionData: actionData,
      isVisible: isVisible,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}