import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
abstract class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    String? enterpriseId,
    required String name,
    required String email,
    @Default('visitor') String role,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) => 
      _$UserDtoFromJson(json);
}

extension UserDtoMapper on UserDto {
  User toEntity(String localId) {
    return User(
      localId: localId,
      remoteId: id,
      enterpriseLocalId: enterpriseId,
      name: name,
      email: email,
      role: _parseRole(role),
      avatarUrl: avatarUrl,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }

  UserRole _parseRole(String role) {
    switch (role) {
      case 'visitor':
        return UserRole.visitor;
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'editor':
        return UserRole.editor;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.visitor;
    }
  }
}

extension UserMapper on User {
  UserDto toDto() {
    return UserDto(
      id: remoteId ?? localId,
      enterpriseId: enterpriseLocalId,
      name: name,
      email: email,
      role: role.name,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}