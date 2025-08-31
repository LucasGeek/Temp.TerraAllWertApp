import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    required String email,
    required String name,
    String? avatar,
    required UserRoleDto role,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isActive,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
}

@freezed
class UserRoleDto with _$UserRoleDto {
  const factory UserRoleDto({
    required String id,
    required String name,
    required String code,
    List<String>? permissions,
  }) = _UserRoleDto;

  factory UserRoleDto.fromJson(Map<String, dynamic> json) => _$UserRoleDtoFromJson(json);
}