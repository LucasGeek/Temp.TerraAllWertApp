import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_queue.freezed.dart';
part 'sync_queue.g.dart';

/// Enum de operações de sincronização
enum SyncOperation { create, update, delete, upsert }

/// Enum de status da fila
enum QueueStatus { pending, processing, success, failed, conflict, cancelled, completed }

@freezed
abstract class SyncQueue with _$SyncQueue {
  const factory SyncQueue({
    /// UUID local (PK)
    required String localId,
    
    /// UUID remoto do servidor
    String? remoteId,

    /// Tipo da entidade (nome da tabela)
    required String entityType,

    /// ID local da entidade
    required String entityLocalId,

    /// UUID remoto (quando já sincronizado)
    String? entityRemoteId,

    /// Operação de sync
    required SyncOperation operation,

    /// JSON com dados da operação
    required Map<String, dynamic> payload,

    /// Status da fila (default: pending)
    @Default(QueueStatus.pending) QueueStatus status,

    /// Prioridade (1–10, 1 = máxima)
    @Default(5) int priority,

    /// Tentativas de envio
    @Default(0) int retryCount,

    /// Última tentativa
    DateTime? lastAttemptAt,

    /// Mensagem de erro
    String? errorMessage,
    
    /// Se foi modificado localmente
    @Default(false) bool isModified,
    
    /// Última modificação local
    DateTime? lastModifiedAt,

    /// Criado em
    required DateTime createdAt,

    /// Atualizado em
    DateTime? updatedAt,

    /// Quando foi processado
    DateTime? processedAt,

    /// Quando foi sincronizado
    DateTime? syncedAt,

    /// Deletado em (soft delete)
    DateTime? deletedAt,
  }) = _SyncQueue;

  factory SyncQueue.fromJson(Map<String, dynamic> json) => _$SyncQueueFromJson(json);
}
