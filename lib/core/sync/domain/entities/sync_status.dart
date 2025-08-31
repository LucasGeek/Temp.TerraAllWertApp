import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_status.freezed.dart';
part 'sync_status.g.dart';

@freezed
abstract class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    required bool isConnected,
    required bool isSyncing,
    required DateTime lastSync,
    Map<String, DateTime>? lastSyncByModule,
    List<String>? failedSyncs,
    String? errorMessage,
  }) = _SyncStatus;

  factory SyncStatus.fromJson(Map<String, dynamic> json) => _$SyncStatusFromJson(json);
}