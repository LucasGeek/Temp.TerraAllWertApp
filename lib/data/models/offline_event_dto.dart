import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/offline_event.dart';

part 'offline_event_dto.freezed.dart';
part 'offline_event_dto.g.dart';

@freezed
abstract class OfflineEventDto with _$OfflineEventDto {
  const factory OfflineEventDto({
    required String id,
    required String eventType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> eventData,
    @Default('pending') String status,
    required DateTime timestamp,
    DateTime? processedAt,
    String? error,
  }) = _OfflineEventDto;

  factory OfflineEventDto.fromJson(Map<String, dynamic> json) => 
      _$OfflineEventDtoFromJson(json);
}

extension OfflineEventDtoMapper on OfflineEventDto {
  OfflineEvent toEntity(String localId) {
    return OfflineEvent(
      localId: localId,
      remoteId: id,
      eventType: eventType,
      entityType: entityType,
      entityLocalId: entityId,
      eventData: eventData,
      sessionId: id, // Use ID as sessionId for now
      createdAt: timestamp,
    );
  }
}

extension OfflineEventEntityMapper on OfflineEvent {
  OfflineEventDto toDto() {
    return OfflineEventDto(
      id: remoteId ?? localId,
      eventType: eventType,
      entityType: entityType ?? 'unknown',
      entityId: entityLocalId ?? 'unknown',
      eventData: eventData ?? {},
      timestamp: createdAt,
    );
  }
}