import '../../entities/suite.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class SearchSuitesParams {
  final String? query;
  final int? minBedrooms;
  final int? maxBedrooms;
  final double? minArea;
  final double? maxArea;
  final double? minPrice;
  final double? maxPrice;
  final String? status;
  
  SearchSuitesParams({
    this.query,
    this.minBedrooms,
    this.maxBedrooms,
    this.minArea,
    this.maxArea,
    this.minPrice,
    this.maxPrice,
    this.status,
  });
}

class SearchSuitesUseCase implements UseCase<List<Suite>, SearchSuitesParams> {
  final TowerRepository _towerRepository;
  
  SearchSuitesUseCase(this._towerRepository);
  
  @override
  Future<List<Suite>> call(SearchSuitesParams params) async {
    try {
      // Validate search parameters
      if (params.minBedrooms != null && params.minBedrooms! < 0) {
        throw Exception('Minimum bedrooms must be non-negative');
      }
      
      if (params.maxBedrooms != null && params.maxBedrooms! < 0) {
        throw Exception('Maximum bedrooms must be non-negative');
      }
      
      if (params.minBedrooms != null && 
          params.maxBedrooms != null && 
          params.minBedrooms! > params.maxBedrooms!) {
        throw Exception('Minimum bedrooms cannot be greater than maximum bedrooms');
      }
      
      if (params.minArea != null && params.minArea! < 0) {
        throw Exception('Minimum area must be non-negative');
      }
      
      if (params.maxArea != null && params.maxArea! < 0) {
        throw Exception('Maximum area must be non-negative');
      }
      
      if (params.minArea != null && 
          params.maxArea != null && 
          params.minArea! > params.maxArea!) {
        throw Exception('Minimum area cannot be greater than maximum area');
      }
      
      if (params.minPrice != null && params.minPrice! < 0) {
        throw Exception('Minimum price must be non-negative');
      }
      
      if (params.maxPrice != null && params.maxPrice! < 0) {
        throw Exception('Maximum price must be non-negative');
      }
      
      if (params.minPrice != null && 
          params.maxPrice != null && 
          params.minPrice! > params.maxPrice!) {
        throw Exception('Minimum price cannot be greater than maximum price');
      }
      
      return await _towerRepository.searchSuites(
        query: params.query,
        minBedrooms: params.minBedrooms,
        maxBedrooms: params.maxBedrooms,
        minArea: params.minArea,
        maxArea: params.maxArea,
        minPrice: params.minPrice,
        maxPrice: params.maxPrice,
        status: params.status,
      );
    } catch (e) {
      throw Exception('Failed to search suites: ${e.toString()}');
    }
  }
}