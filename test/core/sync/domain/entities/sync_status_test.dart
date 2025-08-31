import 'package:flutter_test/flutter_test.dart';
import 'package:terra_allwert_app/infra/sync/domain/entities/sync_status.dart';

void main() {
  group('SyncStatus Entity', () {
    test('should create sync status with required fields', () {
      // Arrange
      final now = DateTime.now();
      final syncStatus = SyncStatus(
        isConnected: true,
        isSyncing: false,
        lastSync: now,
      );

      // Assert
      expect(syncStatus.isConnected, isTrue);
      expect(syncStatus.isSyncing, isFalse);
      expect(syncStatus.lastSync, now);
      expect(syncStatus.lastSyncByModule, isNull);
      expect(syncStatus.failedSyncs, isNull);
      expect(syncStatus.errorMessage, isNull);
    });

    test('should create sync status with optional fields', () {
      // Arrange
      final now = DateTime.now();
      final lastSyncByModule = {
        'towers': now.subtract(const Duration(minutes: 5)),
        'apartments': now.subtract(const Duration(minutes: 3)),
        'gallery': now.subtract(const Duration(minutes: 1)),
      };
      final failedSyncs = ['towers', 'gallery'];

      final syncStatus = SyncStatus(
        isConnected: false,
        isSyncing: true,
        lastSync: now,
        lastSyncByModule: lastSyncByModule,
        failedSyncs: failedSyncs,
        errorMessage: 'Network connection lost',
      );

      // Assert
      expect(syncStatus.isConnected, isFalse);
      expect(syncStatus.isSyncing, isTrue);
      expect(syncStatus.lastSync, now);
      expect(syncStatus.lastSyncByModule, equals(lastSyncByModule));
      expect(syncStatus.failedSyncs, equals(failedSyncs));
      expect(syncStatus.errorMessage, 'Network connection lost');
    });

    test('should support JSON serialization', () {
      // Arrange
      final now = DateTime.now();
      final syncStatus = SyncStatus(
        isConnected: true,
        isSyncing: false,
        lastSync: now,
        lastSyncByModule: {'towers': now},
        failedSyncs: ['apartments'],
        errorMessage: 'Sync error',
      );

      // Act
      final json = syncStatus.toJson();
      final syncStatusFromJson = SyncStatus.fromJson(json);

      // Assert
      expect(syncStatusFromJson.isConnected, syncStatus.isConnected);
      expect(syncStatusFromJson.isSyncing, syncStatus.isSyncing);
      expect(syncStatusFromJson.lastSync, syncStatus.lastSync);
      expect(syncStatusFromJson.errorMessage, syncStatus.errorMessage);
    });

    test('should support equality comparison', () {
      // Arrange
      final now = DateTime.now();
      final syncStatus1 = SyncStatus(
        isConnected: true,
        isSyncing: false,
        lastSync: now,
        errorMessage: 'Test error',
      );

      final syncStatus2 = SyncStatus(
        isConnected: true,
        isSyncing: false,
        lastSync: now,
        errorMessage: 'Test error',
      );

      final syncStatus3 = SyncStatus(
        isConnected: false,
        isSyncing: true,
        lastSync: now,
      );

      // Assert
      expect(syncStatus1, equals(syncStatus2));
      expect(syncStatus1, isNot(equals(syncStatus3)));
    });

    test('should support copyWith method', () {
      // Arrange
      final now = DateTime.now();
      final originalStatus = SyncStatus(
        isConnected: false,
        isSyncing: false,
        lastSync: now,
      );

      // Act
      final updatedStatus = originalStatus.copyWith(
        isConnected: true,
        isSyncing: true,
        errorMessage: 'New error message',
      );

      // Assert
      expect(updatedStatus.isConnected, isTrue);
      expect(updatedStatus.isSyncing, isTrue);
      expect(updatedStatus.lastSync, originalStatus.lastSync);
      expect(updatedStatus.errorMessage, 'New error message');
    });

    test('should handle sync module updates', () {
      // Arrange
      final now = DateTime.now();
      final initialStatus = SyncStatus(
        isConnected: true,
        isSyncing: false,
        lastSync: now,
      );

      final moduleMap = {
        'towers': now.add(const Duration(minutes: 1)),
        'apartments': now.add(const Duration(minutes: 2)),
      };

      // Act
      final updatedStatus = initialStatus.copyWith(
        lastSyncByModule: moduleMap,
      );

      // Assert
      expect(updatedStatus.lastSyncByModule, equals(moduleMap));
      expect(updatedStatus.lastSyncByModule!.containsKey('towers'), isTrue);
      expect(updatedStatus.lastSyncByModule!.containsKey('apartments'), isTrue);
    });

    test('should handle failed syncs list', () {
      // Arrange
      final now = DateTime.now();
      final syncStatus = SyncStatus(
        isConnected: true,
        isSyncing: false,
        lastSync: now,
        failedSyncs: ['towers', 'gallery'],
      );

      // Assert
      expect(syncStatus.failedSyncs, hasLength(2));
      expect(syncStatus.failedSyncs, contains('towers'));
      expect(syncStatus.failedSyncs, contains('gallery'));
      expect(syncStatus.failedSyncs, isNot(contains('apartments')));
    });

    test('should indicate sync health status', () {
      // Arrange
      final now = DateTime.now();
      
      final healthyStatus = SyncStatus(
        isConnected: true,
        isSyncing: false,
        lastSync: now,
        failedSyncs: null,
        errorMessage: null,
      );

      final unhealthyStatus = SyncStatus(
        isConnected: false,
        isSyncing: false,
        lastSync: now.subtract(const Duration(hours: 1)),
        failedSyncs: ['towers', 'apartments'],
        errorMessage: 'Connection timeout',
      );

      // Assert - healthy status
      expect(healthyStatus.isConnected, isTrue);
      expect(healthyStatus.failedSyncs, isNull);
      expect(healthyStatus.errorMessage, isNull);

      // Assert - unhealthy status
      expect(unhealthyStatus.isConnected, isFalse);
      expect(unhealthyStatus.failedSyncs, isNotEmpty);
      expect(unhealthyStatus.errorMessage, isNotNull);
    });
  });
}