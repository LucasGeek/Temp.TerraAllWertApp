import 'package:freezed_annotation/freezed_annotation.dart';

part 'offline_event.freezed.dart';
part 'offline_event.g.dart';

/// Tipo de rede
enum NetworkType { wifi, g4, g3, offline }

@freezed
abstract class OfflineEvent with _$OfflineEvent {
  const factory OfflineEvent({
    /// UUID local (PK)
    required String localId,
    
    /// UUID remoto do servidor
    String? remoteId,

    /// Tipo do evento
    required String eventType,

    /// Tipo da entidade relacionada
    String? entityType,

    /// ID local da entidade
    String? entityLocalId,

    /// Dados do evento em JSON
    Map<String, dynamic>? eventData,

    /// Usuário local
    String? userLocalId,

    /// Sessão
    required String sessionId,

    /// Device info
    String? deviceId,
    String? deviceModel,
    String? osVersion,
    String? appVersion,

    /// Tipo de rede
    NetworkType? networkType,

    /// Localização
    double? latitude,
    double? longitude,

    /// Status de sync
    @Default(false) bool isSynced,
    DateTime? syncedAt,

    /// Se foi modificado localmente
    @Default(false) bool isModified,

    /// Última modificação local
    DateTime? lastModifiedAt,

    /// Criado em
    required DateTime createdAt,

    /// Atualizado em
    DateTime? updatedAt,

    /// Deletado em (soft delete)
    DateTime? deletedAt,
  }) = _OfflineEvent;

  factory OfflineEvent.fromJson(Map<String, dynamic> json) => _$OfflineEventFromJson(json);
}
