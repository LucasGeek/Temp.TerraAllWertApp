import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    String? avatar,
    required UserRole role,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
abstract class UserRole with _$UserRole {
  const factory UserRole({
    required String id,
    required String name,
    required String code,
    List<String>? permissions,
  }) = _UserRole;

  factory UserRole.fromJson(Map<String, dynamic> json) => _$UserRoleFromJson(json);
}