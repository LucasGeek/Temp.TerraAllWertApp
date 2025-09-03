import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user_preferences.dart';

part 'user_preferences_dto.freezed.dart';
part 'user_preferences_dto.g.dart';

@freezed
abstract class UserPreferencesDto with _$UserPreferencesDto {
  const factory UserPreferencesDto({
    required String id,
    required String userId,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserPreferencesDto;

  factory UserPreferencesDto.fromJson(Map<String, dynamic> json) => 
      _$UserPreferencesDtoFromJson(json);
}

extension UserPreferencesDtoMapper on UserPreferencesDto {
  UserPreferences toEntity(String localId) {
    return UserPreferences(
      localId: localId,
      remoteId: id,
      userLocalId: userId,
      preferences: preferences,
      createdAt: createdAt ?? DateTime.now(),
      lastModifiedAt: updatedAt,
    );
  }
}

extension UserPreferencesEntityMapper on UserPreferences {
  UserPreferencesDto toDto() {
    return UserPreferencesDto(
      id: remoteId ?? localId,
      userId: userLocalId,
      preferences: preferences,
      createdAt: createdAt,
      updatedAt: lastModifiedAt,
    );
  }
}