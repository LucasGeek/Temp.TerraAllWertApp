import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/menu_pin.dart';

part 'menu_pin_dto.freezed.dart';
part 'menu_pin_dto.g.dart';

@freezed
abstract class MenuPinDto with _$MenuPinDto {
  const factory MenuPinDto({
    required String id,
    required String menuId,
    required String pinMarkerId,
    @Default(0) int position,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MenuPinDto;

  factory MenuPinDto.fromJson(Map<String, dynamic> json) => 
      _$MenuPinDtoFromJson(json);
}

extension MenuPinDtoMapper on MenuPinDto {
  MenuPin toEntity(String localId) {
    return MenuPin(
      localId: localId,
      remoteId: id,
      menuLocalId: menuId,
      createdAt: createdAt ?? DateTime.now(),
      lastModifiedAt: updatedAt,
    );
  }
}

extension MenuPinEntityMapper on MenuPin {
  MenuPinDto toDto() {
    return MenuPinDto(
      id: remoteId ?? localId,
      menuId: menuLocalId,
      pinMarkerId: '', // Default empty pin marker ID
      position: 0, // Default position
      isActive: true, // Default active
      createdAt: createdAt,
      updatedAt: lastModifiedAt,
    );
  }
}