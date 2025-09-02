import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
abstract class UserDto with _$UserDto {
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

  factory UserDto.fromJson(Map<String, dynamic> json) {
    // Handle role conversion from enum string to object
    UserRoleDto role;
    final roleValue = json['role'];
    
    if (roleValue is String) {
      // API returns role as enum string (ADMIN/VIEWER)
      role = UserRoleDto(
        id: roleValue.toLowerCase(),
        name: roleValue == 'ADMIN' ? 'Administrador' : 'Visualizador',
        code: roleValue,
        permissions: roleValue == 'ADMIN' ? ['create', 'read', 'update', 'delete'] : ['read'],
      );
    } else if (roleValue is Map<String, dynamic>) {
      // Role as object (legacy support)
      role = UserRoleDto.fromJson(roleValue);
    } else {
      // Fallback
      role = const UserRoleDto(
        id: 'viewer',
        name: 'Visualizador',
        code: 'VIEWER',
        permissions: ['read'],
      );
    }

    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['username'] as String? ?? json['name'] as String, // API uses 'username'
      avatar: json['avatar'] as String?,
      role: role,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['active'] as bool? ?? false, // API uses 'active'
    );
  }
}

extension UserDtoExtension on UserDto {
  Map<String, dynamic> toStorageJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'username': name, // API expects username
      'avatar': avatar,
      'role': role.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'active': isActive, // API expects active
    };
  }
}

@freezed
abstract class UserRoleDto with _$UserRoleDto {
  const factory UserRoleDto({
    required String id,
    required String name,
    required String code,
    List<String>? permissions,
  }) = _UserRoleDto;

  factory UserRoleDto.fromJson(Map<String, dynamic> json) => _$UserRoleDtoFromJson(json);
}