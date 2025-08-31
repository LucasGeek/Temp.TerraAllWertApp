import '../entities/sync_status.dart';

abstract class SyncRepository {
  Future<void> syncAll();
  Future<void> syncTowers();
  Future<void> syncApartments();
  Future<void> syncGallery();
  Future<bool> isOnline();
  Future<SyncStatus> getSyncStatus();
  Stream<SyncStatus> watchSyncStatus();
  Stream<bool> watchConnectivity();
  Future<void> clearCache();
  Future<void> downloadBulkData(String downloadUrl);
}