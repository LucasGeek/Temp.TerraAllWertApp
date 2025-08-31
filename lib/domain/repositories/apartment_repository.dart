import '../entities/apartment.dart';

abstract class ApartmentRepository {
  Future<List<Apartment>> getApartments();
  Future<List<Apartment>> getApartmentsByTower(String towerId);
  Future<List<Apartment>> getApartmentsByPavimento(String pavimentoId);
  Future<Apartment?> getApartmentById(String id);
  Future<Apartment> createApartment(Apartment apartment);
  Future<Apartment> updateApartment(Apartment apartment);
  Future<void> deleteApartment(String id);
  Future<List<Apartment>> searchApartments({
    String? query,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    double? minArea,
    double? maxArea,
    bool? isAvailable,
    String? towerId,
  });
  Future<void> syncApartments();
  Stream<List<Apartment>> watchApartments();
  Stream<Apartment?> watchApartmentById(String id);
}