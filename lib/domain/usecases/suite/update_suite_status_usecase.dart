import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class UpdateSuiteStatusParams {
  final String suiteLocalId;
  final String status; // 'available', 'reserved', 'sold', 'unavailable'
  
  UpdateSuiteStatusParams({
    required this.suiteLocalId,
    required this.status,
  });
}

class UpdateSuiteStatusUseCase implements VoidUseCase<UpdateSuiteStatusParams> {
  final TowerRepository _towerRepository;
  
  UpdateSuiteStatusUseCase(this._towerRepository);
  
  @override
  Future<void> call(UpdateSuiteStatusParams params) async {
    try {
      // Validate status
      final validStatuses = ['available', 'reserved', 'sold', 'unavailable'];
      if (!validStatuses.contains(params.status)) {
        throw Exception('Invalid status. Must be one of: ${validStatuses.join(", ")}');
      }
      
      await _towerRepository.updateSuiteStatus(
        params.suiteLocalId,
        params.status,
      );
    } catch (e) {
      throw Exception('Failed to update suite status: ${e.toString()}');
    }
  }
}