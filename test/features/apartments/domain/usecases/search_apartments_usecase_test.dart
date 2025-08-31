import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terra_allwert_app/domain/entities/apartment.dart';
import 'package:terra_allwert_app/domain/entities/apartment_type.dart';
import 'package:terra_allwert_app/domain/repositories/apartment_repository.dart';
import 'package:terra_allwert_app/domain/usecases/search_apartments_usecase.dart';

class MockApartmentRepository extends Mock implements ApartmentRepository {}

void main() {
  group('SearchApartmentsUseCase', () {
    late SearchApartmentsUseCase useCase;
    late MockApartmentRepository mockRepository;

    setUp(() {
      mockRepository = MockApartmentRepository();
      useCase = SearchApartmentsUseCase(mockRepository);
    });

    test('should return list of apartments from repository', () async {
      // Arrange
      final apartmentType = ApartmentType(
        id: '1',
        name: 'Tipo 1',
        code: 'T1',
      );

      final apartments = [
        Apartment(
          id: '1',
          pavimentoId: 'pav1',
          towerId: 'tower1',
          number: '101',
          type: apartmentType,
          area: 80.0,
          bedrooms: 2,
          bathrooms: 1,
          isAvailable: true,
        ),
        Apartment(
          id: '2',
          pavimentoId: 'pav1',
          towerId: 'tower1',
          number: '102',
          type: apartmentType,
          area: 90.0,
          bedrooms: 3,
          bathrooms: 2,
          isAvailable: true,
        ),
      ];

      when(() => mockRepository.searchApartments(
        query: any(named: 'query'),
        minPrice: any(named: 'minPrice'),
        maxPrice: any(named: 'maxPrice'),
        bedrooms: any(named: 'bedrooms'),
        minArea: any(named: 'minArea'),
        maxArea: any(named: 'maxArea'),
        isAvailable: any(named: 'isAvailable'),
        towerId: any(named: 'towerId'),
      )).thenAnswer((_) async => apartments);

      // Act
      final result = await useCase(
        query: 'apartamento',
        bedrooms: 2,
        isAvailable: true,
      );

      // Assert
      expect(result, equals(apartments));
      verify(() => mockRepository.searchApartments(
        query: 'apartamento',
        bedrooms: 2,
        isAvailable: true,
      )).called(1);
    });

    test('should call repository with correct parameters', () async {
      // Arrange
      when(() => mockRepository.searchApartments(
        query: any(named: 'query'),
        minPrice: any(named: 'minPrice'),
        maxPrice: any(named: 'maxPrice'),
        bedrooms: any(named: 'bedrooms'),
        minArea: any(named: 'minArea'),
        maxArea: any(named: 'maxArea'),
        isAvailable: any(named: 'isAvailable'),
        towerId: any(named: 'towerId'),
      )).thenAnswer((_) async => []);

      // Act
      await useCase(
        query: 'test',
        minPrice: 100000.0,
        maxPrice: 200000.0,
        bedrooms: 3,
        minArea: 70.0,
        maxArea: 120.0,
        isAvailable: true,
        towerId: 'tower123',
      );

      // Assert
      verify(() => mockRepository.searchApartments(
        query: 'test',
        minPrice: 100000.0,
        maxPrice: 200000.0,
        bedrooms: 3,
        minArea: 70.0,
        maxArea: 120.0,
        isAvailable: true,
        towerId: 'tower123',
      )).called(1);
    });
  });
}