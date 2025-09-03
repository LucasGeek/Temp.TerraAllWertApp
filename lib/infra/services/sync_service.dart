import '../../domain/repositories/sync_metadata_repository.dart';
import '../../domain/repositories/offline_event_repository.dart';
import '../../domain/repositories/conflict_resolution_repository.dart';

class SyncService {
  final SyncMetadataRepository _syncMetadataRepository;
  final OfflineEventRepository _offlineEventRepository;
  final ConflictResolutionRepository _conflictRepository;
  
  SyncService(
    this._syncMetadataRepository,
    this._offlineEventRepository,
    this._conflictRepository,
  );
  
  /// Performs a full synchronization of all data
  Future<SyncResult> performFullSync() async {
    final result = SyncResult();
    
    try {
      // Step 1: Process pending offline events
      final processedEvents = await _processOfflineEvents();
      result.processedEvents = processedEvents;
      
      // Step 2: Resolve conflicts
      final resolvedConflicts = await _resolveConflicts();
      result.resolvedConflicts = resolvedConflicts;
      
      // Step 3: Sync metadata
      await _syncMetadataRepository.syncFromRemote();
      await _syncMetadataRepository.syncToRemote();
      
      result.success = true;
      result.timestamp = DateTime.now();
      
    } catch (e) {
      result.success = false;
      result.error = e.toString();
    }
    
    return result;
  }
  
  /// Processes pending offline events
  Future<int> _processOfflineEvents() async {
    try {
      final pendingEvents = await _offlineEventRepository.getPending();
      int processedCount = 0;
      
      // Process events in batches of 10
      const batchSize = 10;
      for (int i = 0; i < pendingEvents.length; i += batchSize) {
        final batch = pendingEvents.skip(i).take(batchSize).toList();
        
        for (final event in batch) {
          try {
            // Mark as processed
            await _offlineEventRepository.markAsProcessed(event.localId);
            processedCount++;
          } catch (e) {
            // Mark as failed
            await _offlineEventRepository.markAsFailed(event.localId, e.toString());
          }
        }
      }
      
      return processedCount;
    } catch (e) {
      throw Exception('Failed to process offline events: ${e.toString()}');
    }
  }
  
  /// Resolves pending conflicts
  Future<int> _resolveConflicts() async {
    try {
      final pendingConflicts = await _conflictRepository.getPending();
      int resolvedCount = 0;
      
      for (final conflict in pendingConflicts) {
        try {
          // Auto-resolve based on simple rules (remote wins by default)
          await _conflictRepository.resolveWithRemote(conflict.localId);
          resolvedCount++;
        } catch (e) {
          // Log conflict resolution failure but continue
          continue;
        }
      }
      
      return resolvedCount;
    } catch (e) {
      throw Exception('Failed to resolve conflicts: ${e.toString()}');
    }
  }
  
  /// Checks if sync is needed
  Future<bool> isSyncNeeded() async {
    try {
      final pendingEvents = await _offlineEventRepository.getPending();
      final pendingConflicts = await _conflictRepository.getPending();
      final outdatedMetadata = await _syncMetadataRepository.getOutdated();
      
      return pendingEvents.isNotEmpty || 
             pendingConflicts.isNotEmpty || 
             outdatedMetadata.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Gets sync status
  Future<SyncStatus> getSyncStatus() async {
    try {
      final pendingEvents = await _offlineEventRepository.getPending();
      final failedEvents = await _offlineEventRepository.getFailed();
      final pendingConflicts = await _conflictRepository.getPending();
      
      return SyncStatus(
        pendingEventsCount: pendingEvents.length,
        failedEventsCount: failedEvents.length,
        pendingConflictsCount: pendingConflicts.length,
        lastSyncTime: await _getLastSyncTime(),
      );
    } catch (e) {
      return SyncStatus(
        pendingEventsCount: 0,
        failedEventsCount: 0,
        pendingConflictsCount: 0,
        lastSyncTime: null,
      );
    }
  }
  
  Future<DateTime?> _getLastSyncTime() async {
    // This would typically be stored in metadata or preferences
    // For now, return null
    return null;
  }
}

class SyncResult {
  bool success = false;
  int processedEvents = 0;
  int resolvedConflicts = 0;
  DateTime? timestamp;
  String? error;
}

class SyncStatus {
  final int pendingEventsCount;
  final int failedEventsCount;
  final int pendingConflictsCount;
  final DateTime? lastSyncTime;
  
  SyncStatus({
    required this.pendingEventsCount,
    required this.failedEventsCount,
    required this.pendingConflictsCount,
    this.lastSyncTime,
  });
  
  bool get hasWork => pendingEventsCount > 0 || failedEventsCount > 0 || pendingConflictsCount > 0;
}