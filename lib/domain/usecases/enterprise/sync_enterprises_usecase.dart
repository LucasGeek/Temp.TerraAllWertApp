import '../../repositories/enterprise_repository.dart';
import '../usecase.dart';

class SyncEnterprisesUseCase implements NoParamsUseCase<void> {
  final EnterpriseRepository _repository;
  
  SyncEnterprisesUseCase(this._repository);
  
  @override
  Future<void> call() async {
    try {
      await _repository.syncWithRemote();
    } catch (e) {
      throw Exception('Failed to sync enterprises: ${e.toString()}');
    }
  }
}