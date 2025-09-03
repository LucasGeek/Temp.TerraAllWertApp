import 'user_dto.dart';

/// Classe para parsing da resposta de login da API
class AuthResponseDto {
  final UserDto user;
  final String accessToken;
  final String refreshToken;
  final String? accessTokenExpiresAt;
  final String? refreshTokenExpiresAt;
  final String? tokenType;
  final String message;

  const AuthResponseDto({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
    this.tokenType,
    required this.message,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    final tokensJson = json['tokens'] as Map<String, dynamic>;

    return AuthResponseDto(
      user: UserDto.fromJson(userJson),
      accessToken: tokensJson['access_token'] as String,
      refreshToken: tokensJson['refresh_token'] as String,
      accessTokenExpiresAt: tokensJson['access_token_expires_at'] as String?,
      refreshTokenExpiresAt: tokensJson['refresh_token_expires_at'] as String?,
      tokenType: tokensJson['token_type'] as String?,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'tokens': {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        if (accessTokenExpiresAt != null) 'access_token_expires_at': accessTokenExpiresAt,
        if (refreshTokenExpiresAt != null) 'refresh_token_expires_at': refreshTokenExpiresAt,
        if (tokenType != null) 'token_type': tokenType,
      },
      'message': message,
    };
  }
}