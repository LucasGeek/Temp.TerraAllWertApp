import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../models/auth_response.dart';
import '../models/user_dto.dart';

class AuthMapper {
  static AuthToken responseToToken(AuthResponse response) {
    return AuthToken(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      expiresAt: response.expiresAt,
      tokenType: response.tokenType,
    );
  }

  static User dtoToUser(UserDto dto) {
    return User(
      id: dto.id,
      email: dto.email,
      name: dto.name,
      avatar: dto.avatar,
      role: UserRole(
        id: dto.role.id,
        name: dto.role.name,
        code: dto.role.code,
        permissions: dto.role.permissions,
      ),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      isActive: dto.isActive,
    );
  }

  static UserDto userToDto(User user) {
    return UserDto(
      id: user.id,
      email: user.email,
      name: user.name,
      avatar: user.avatar,
      role: UserRoleDto(
        id: user.role.id,
        name: user.role.name,
        code: user.role.code,
        permissions: user.role.permissions,
      ),
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isActive: user.isActive,
    );
  }
}