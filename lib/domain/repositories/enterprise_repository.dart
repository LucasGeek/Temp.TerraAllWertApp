import '../entities/enterprise.dart';

abstract class EnterpriseRepository {
  // Remote operations
  Future<List<Enterprise>> getAll();
  Future<Enterprise?> getById(String id);
  Future<Enterprise?> getBySlug(String slug);
  Future<Enterprise> create(Enterprise enterprise);
  Future<Enterprise> update(Enterprise enterprise);
  Future<void> delete(String id);
  
  // Local operations
  Future<List<Enterprise>> getAllLocal();
  Future<Enterprise?> getByIdLocal(String localId);
  Future<void> saveLocal(Enterprise enterprise);
  Future<void> saveAllLocal(List<Enterprise> enterprises);
  Future<void> deleteLocal(String localId);
  Future<void> clearLocal();
  
  // Sync operations
  Future<void> syncWithRemote();
  Future<bool> hasLocalChanges();
  Stream<List<Enterprise>> watchAll();
}