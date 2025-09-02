import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_dto.dart';

part 'auth_response.freezed.dart';

@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    required String tokenType,
    UserDto? user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      tokenType: json['tokenType'] as String,
      user: json['user'] != null ? UserDto.fromJson(json['user']) : null,
    );
  }
}

extension AuthResponseExtension on AuthResponse {
  Map<String, dynamic> toStorageJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'tokenType': tokenType,
      'user': user?.toStorageJson(),
    };
  }
}