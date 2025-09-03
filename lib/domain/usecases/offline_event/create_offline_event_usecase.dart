import '../../entities/offline_event.dart';
import '../../repositories/offline_event_repository.dart';
import '../usecase.dart';

class CreateOfflineEventParams {
  final String eventType;
  final String? entityType;
  final String? entityLocalId;
  final Map<String, dynamic>? eventData;
  final String sessionId;
  final String? userLocalId;
  
  CreateOfflineEventParams({
    required this.eventType,
    this.entityType,
    this.entityLocalId,
    this.eventData,
    required this.sessionId,
    this.userLocalId,
  });
}

class CreateOfflineEventUseCase implements UseCase<OfflineEvent, CreateOfflineEventParams> {
  final OfflineEventRepository _repository;
  
  CreateOfflineEventUseCase(this._repository);
  
  @override
  Future<OfflineEvent> call(CreateOfflineEventParams params) async {
    try {
      // Validate event data
      if (params.eventType.trim().isEmpty) {
        throw Exception('Event type cannot be empty');
      }
      
      if (params.sessionId.trim().isEmpty) {
        throw Exception('Session ID cannot be empty');
      }
      
      // Create offline event
      final offlineEvent = OfflineEvent(
        localId: DateTime.now().millisecondsSinceEpoch.toString(),
        eventType: params.eventType.trim(),
        entityType: params.entityType?.trim(),
        entityLocalId: params.entityLocalId?.trim(),
        eventData: params.eventData,
        sessionId: params.sessionId.trim(),
        userLocalId: params.userLocalId,
        createdAt: DateTime.now(),
      );
      
      return await _repository.create(offlineEvent);
    } catch (e) {
      throw Exception('Failed to create offline event: ${e.toString()}');
    }
  }
}