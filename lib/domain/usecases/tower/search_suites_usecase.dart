import '../../entities/suite.dart';
import '../../repositories/tower_repository.dart';

class SearchSuitesUseCase {
  final TowerRepository _repository;

  SearchSuitesUseCase(this._repository);

  Future<List<Suite>> execute({
    String? query,
    int? minBedrooms,
    int? maxBedrooms,
    double? minArea,
    double? maxArea,
    double? minPrice,
    double? maxPrice,
    String? status,
    bool onlyFavorites = false,
  }) async {
    try {
      // Search suites
      var suites = await _repository.searchSuites(
        query: query,
        minBedrooms: minBedrooms,
        maxBedrooms: maxBedrooms,
        minArea: minArea,
        maxArea: maxArea,
        minPrice: minPrice,
        maxPrice: maxPrice,
        status: status,
      );
      
      // Filter favorites if requested
      if (onlyFavorites) {
        suites = suites.where((suite) => suite.isFavorite).toList();
      }
      
      // Sort by multiple criteria
      suites.sort((a, b) {
        // Favorites first
        if (a.isFavorite != b.isFavorite) {
          return a.isFavorite ? -1 : 1;
        }
        
        // Then by status (available first)
        if (a.status != b.status) {
          if (a.status == SuiteStatus.available) return -1;
          if (b.status == SuiteStatus.available) return 1;
        }
        
        // Then by price (lower first)
        if (a.price != null && b.price != null) {
          return a.price!.compareTo(b.price!);
        }
        
        return 0;
      });
      
      return suites;
    } catch (e) {
      throw Exception('Failed to search suites: ${e.toString()}');
    }
  }
}