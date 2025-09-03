import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_metadata.freezed.dart';
part 'sync_metadata.g.dart';

enum SyncStatus { idle, pending, syncing, error, conflict }

@freezed
abstract class SyncMetadata with _$SyncMetadata {
  const factory SyncMetadata({
    /// UUID local (PK)
    required String localId,
    
    /// UUID remoto do servidor
    String? remoteId,
    
    /// Tipo da entidade (nome da tabela)
    required String entityType,
    
    /// ID local da entidade
    required String entityLocalId,
    
    /// Última sincronização
    DateTime? lastSyncedAt,
    
    /// Versão do sync
    String? lastSyncVersion,
    
    /// Versão atual (para controle)
    @Default(1) int version,
    
    /// Checksum para verificação de integridade
    String? checksum,
    
    /// Status de sincronização
    @Default(SyncStatus.pending) SyncStatus syncStatus,
    
    /// Contador de mudanças pendentes
    @Default(0) int pendingChangesCount,
    
    /// Último erro
    String? lastError,
    
    /// Contador de tentativas
    @Default(0) int retryCount,
    
    /// Próxima tentativa
    DateTime? nextRetryAt,
    
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
  }) = _SyncMetadata;

  factory SyncMetadata.fromJson(Map<String, dynamic> json) => _$SyncMetadataFromJson(json);
}
