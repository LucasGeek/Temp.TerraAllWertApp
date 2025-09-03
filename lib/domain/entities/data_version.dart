import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_version.freezed.dart';
part 'data_version.g.dart';

/// Tipo de mudança
enum ChangeType { create, update, delete, restore }

@freezed
abstract class DataVersion with _$DataVersion {
  const factory DataVersion({
    /// UUID local (PK)
    required String localId,
    
    /// UUID remoto do servidor
    String? remoteId,

    /// Tipo da entidade
    required String entityType,

    /// ID local da entidade
    required String entityLocalId,

    /// Número da versão
    required int versionNumber,

    /// Tipo da mudança
    required ChangeType changeType,

    /// Campos alterados (JSON array)
    List<String>? changedFields,

    /// Valores antigos
    Map<String, dynamic>? oldValues,

    /// Valores novos
    Map<String, dynamic>? newValues,

    /// Quem alterou (usuário local)
    String? changedByLocalId,

    /// Device ID
    String? deviceId,
    
    /// Se foi modificado localmente
    @Default(false) bool isModified,
    
    /// Última modificação local
    DateTime? lastModifiedAt,

    /// Criado em
    required DateTime createdAt,
  }) = _DataVersion;

  factory DataVersion.fromJson(Map<String, dynamic> json) => _$DataVersionFromJson(json);
}
