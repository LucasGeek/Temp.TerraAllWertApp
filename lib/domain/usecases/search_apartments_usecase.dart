import '../entities/apartment.dart';
import '../repositories/apartment_repository.dart';

class SearchApartmentsUseCase {
  final ApartmentRepository _repository;

  const SearchApartmentsUseCase(this._repository);

  Future<List<Apartment>> call({
    String? query,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    double? minArea,
    double? maxArea,
    bool? isAvailable,
    String? towerId,
  }) async {
    return await _repository.searchApartments(
      query: query,
      minPrice: minPrice,
      maxPrice: maxPrice,
      bedrooms: bedrooms,
      minArea: minArea,
      maxArea: maxArea,
      isAvailable: isAvailable,
      towerId: towerId,
    );
  }
}