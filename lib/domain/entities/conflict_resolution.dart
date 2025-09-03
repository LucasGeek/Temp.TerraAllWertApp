import 'package:freezed_annotation/freezed_annotation.dart';

part 'conflict_resolution.freezed.dart';
part 'conflict_resolution.g.dart';

/// Tipo de conflito
enum ConflictType { concurrentUpdate, deletedRemotely, deletedLocally, versionMismatch }

/// Estratégia de resolução
enum ResolutionStrategy { localWins, remoteWins, merge, manual }

@freezed
abstract class ConflictResolution with _$ConflictResolution {
  const factory ConflictResolution({
    /// UUID local (PK)
    required String localId,
    
    /// UUID remoto do servidor
    String? remoteId,

    /// Tipo da entidade (tabela)
    required String entityType,

    /// ID local da entidade
    required String entityLocalId,

    /// ID remoto (UUID do servidor)
    String? entityRemoteId,

    /// JSON com dados locais
    required Map<String, dynamic> localData,

    /// JSON com dados do servidor
    required Map<String, dynamic> remoteData,

    /// Tipo do conflito
    required ConflictType conflictType,

    /// Estratégia de resolução (pode ser nula até ser definida)
    ResolutionStrategy? resolutionStrategy,

    /// JSON com dados resolvidos
    Map<String, dynamic>? resolvedData,

    /// Quando foi resolvido
    DateTime? resolvedAt,

    /// Quem resolveu (usuário)
    String? resolvedBy,

    /// Se foi resolvido
    @Default(false) bool isResolved,

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
  }) = _ConflictResolution;

  factory ConflictResolution.fromJson(Map<String, dynamic> json) =>
      _$ConflictResolutionFromJson(json);
}
