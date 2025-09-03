import '../../repositories/sync_repository.dart';
import '../usecase.dart';

class SyncEntityParams {
  final String entityType;
  final String entityLocalId;
  
  SyncEntityParams({
    required this.entityType,
    required this.entityLocalId,
  });
}

class SyncEntityUseCase implements VoidUseCase<SyncEntityParams> {
  final SyncRepository _syncRepository;
  
  SyncEntityUseCase(this._syncRepository);
  
  @override
  Future<void> call(SyncEntityParams params) async {
    try {
      // Validate entity type
      if (params.entityType.trim().isEmpty) {
        throw Exception('Entity type cannot be empty');
      }
      
      if (params.entityLocalId.trim().isEmpty) {
        throw Exception('Entity local ID cannot be empty');
      }
      
      await _syncRepository.syncEntity(
        params.entityType,
        params.entityLocalId,
      );
    } catch (e) {
      throw Exception('Failed to sync entity: ${e.toString()}');
    }
  }
}