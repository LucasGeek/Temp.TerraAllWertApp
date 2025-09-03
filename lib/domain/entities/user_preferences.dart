import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

/// Qualidade de cache
enum CacheQuality { low, medium, high }

/// Tema do app
enum AppTheme { light, dark, system }

@freezed
abstract class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    /// UUID local (PK)
    required String localId,
    
    /// UUID remoto do servidor
    String? remoteId,

    /// FK para usuário
    required String userLocalId,

    // ---- Sync preferences ----
    @Default(true) bool autoSyncEnabled,
    @Default(false) bool syncOnWifiOnly,
    @Default(30) int syncIntervalMinutes,

    // ---- Cache preferences ----
    @Default(500) int maxCacheSizeMb,
    @Default(true) bool autoCacheImages,
    @Default(false) bool autoCacheVideos,
    @Default(CacheQuality.medium) CacheQuality cacheQuality,

    // ---- Offline preferences ----
    @Default(false) bool offlineModeEnabled,
    @Default(false) bool downloadFavoritesOnly,

    // ---- UI preferences ----
    @Default('pt-BR') String language,
    @Default(AppTheme.system) AppTheme theme,

    // ---- Notification preferences ----
    @Default(true) bool pushEnabled,
    @Default(true) bool emailEnabled,

    // ---- Data ----
    DateTime? lastSyncPromptAt,
    
    /// Se foi modificado localmente
    @Default(false) bool isModified,
    
    /// Última modificação local
    DateTime? lastModifiedAt,
    
    /// Preferências adicionais como JSON
    Map<String, dynamic>? preferences,

    /// Criado em
    required DateTime createdAt,

    /// Atualizado em
    DateTime? updatedAt,

    /// Deletado em (soft delete)
    DateTime? deletedAt,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) => _$UserPreferencesFromJson(json);
}
