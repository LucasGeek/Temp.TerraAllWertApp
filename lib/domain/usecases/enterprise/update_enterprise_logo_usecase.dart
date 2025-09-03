import '../../entities/enterprise.dart';
import '../../repositories/enterprise_repository.dart';
import '../usecase.dart';

class UpdateEnterpriseLogoParams {
  final String enterpriseLocalId;
  final String logoUrl;
  
  UpdateEnterpriseLogoParams({
    required this.enterpriseLocalId,
    required this.logoUrl,
  });
}

class UpdateEnterpriseLogoUseCase implements UseCase<Enterprise, UpdateEnterpriseLogoParams> {
  final EnterpriseRepository _repository;
  
  UpdateEnterpriseLogoUseCase(this._repository);
  
  @override
  Future<Enterprise> call(UpdateEnterpriseLogoParams params) async {
    try {
      // Validate logo URL
      if (params.logoUrl.trim().isEmpty) {
        throw Exception('Logo URL cannot be empty');
      }
      
      if (!_isValidUrl(params.logoUrl)) {
        throw Exception('Invalid logo URL format');
      }
      
      // Get current enterprise
      final currentEnterprise = await _repository.getByIdLocal(params.enterpriseLocalId);
      if (currentEnterprise == null) {
        throw Exception('Enterprise not found');
      }
      
      // Update enterprise with new logo
      final updatedEnterprise = currentEnterprise.copyWith(
        logoUrl: params.logoUrl.trim(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      // Save locally
      await _repository.saveLocal(updatedEnterprise);
      
      return updatedEnterprise;
    } catch (e) {
      throw Exception('Failed to update enterprise logo: ${e.toString()}');
    }
  }
  
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}