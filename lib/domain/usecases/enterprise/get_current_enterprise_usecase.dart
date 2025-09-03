import '../../entities/enterprise.dart';
import '../../repositories/enterprise_repository.dart';
import '../usecase.dart';

class GetCurrentEnterpriseUseCase implements NoParamsUseCase<Enterprise?> {
  final EnterpriseRepository _repository;
  
  GetCurrentEnterpriseUseCase(this._repository);
  
  @override
  Future<Enterprise?> call() async {
    try {
      // Try to get from local first
      final localEnterprises = await _repository.getAllLocal();
      if (localEnterprises.isNotEmpty) {
        // Return the first active enterprise
        return localEnterprises.firstWhere(
          (e) => e.isActive,
          orElse: () => localEnterprises.first,
        );
      }
      
      // Fallback to remote if not found locally
      final remoteEnterprises = await _repository.getAll();
      if (remoteEnterprises.isNotEmpty) {
        final currentEnterprise = remoteEnterprises.firstWhere(
          (e) => e.isActive,
          orElse: () => remoteEnterprises.first,
        );
        
        // Save locally for offline access
        await _repository.saveLocal(currentEnterprise);
        return currentEnterprise;
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get current enterprise: ${e.toString()}');
    }
  }
}