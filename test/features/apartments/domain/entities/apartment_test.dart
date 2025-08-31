import 'package:flutter_test/flutter_test.dart';
import 'package:terra_allwert_app/presentation/features/apartments/domain/entities/apartment.dart';
import 'package:terra_allwert_app/presentation/features/apartments/domain/entities/apartment_type.dart';

void main() {
  group('Apartment Entity', () {
    final apartmentType = ApartmentType(
      id: '1',
      name: 'Padrão',
      code: 'PAD',
      description: 'Apartamento padrão',
    );

    test('should create apartment with required fields', () {
      // Arrange
      final apartment = Apartment(
        id: '1',
        pavimentoId: 'pav1',
        towerId: 'tower1',
        number: '101',
        type: apartmentType,
        area: 85.5,
        bedrooms: 2,
        bathrooms: 2,
      );

      // Assert
      expect(apartment.id, '1');
      expect(apartment.pavimentoId, 'pav1');
      expect(apartment.towerId, 'tower1');
      expect(apartment.number, '101');
      expect(apartment.area, 85.5);
      expect(apartment.bedrooms, 2);
      expect(apartment.bathrooms, 2);
      expect(apartment.type, apartmentType);
      expect(apartment.isAvailable, isFalse);
      expect(apartment.isSynced, isFalse);
    });

    test('should create apartment with optional fields', () {
      // Arrange
      final apartment = Apartment(
        id: '2',
        pavimentoId: 'pav2',
        towerId: 'tower2',
        number: '201',
        type: apartmentType,
        area: 120.0,
        bedrooms: 3,
        bathrooms: 3,
        price: 350000.0,
        description: 'Apartamento luxuoso',
        imageUrls: ['image1.jpg', 'image2.jpg'],
        isAvailable: true,
      );

      // Assert
      expect(apartment.description, 'Apartamento luxuoso');
      expect(apartment.price, 350000.0);
      expect(apartment.imageUrls, hasLength(2));
      expect(apartment.imageUrls, contains('image1.jpg'));
      expect(apartment.isAvailable, isTrue);
    });

    test('should support JSON serialization', () {
      // Arrange
      final apartment = Apartment(
        id: '1',
        pavimentoId: 'pav1',
        towerId: 'tower1',
        number: '101',
        type: apartmentType,
        area: 85.5,
        bedrooms: 2,
        bathrooms: 2,
        price: 250000.0,
        isAvailable: true,
      );

      // Act
      final json = apartment.toJson();
      final apartmentFromJson = Apartment.fromJson(json);

      // Assert
      expect(apartmentFromJson.id, apartment.id);
      expect(apartmentFromJson.number, apartment.number);
      expect(apartmentFromJson.area, apartment.area);
      expect(apartmentFromJson.bedrooms, apartment.bedrooms);
      expect(apartmentFromJson.bathrooms, apartment.bathrooms);
      expect(apartmentFromJson.price, apartment.price);
      expect(apartmentFromJson.isAvailable, apartment.isAvailable);
    });

    test('should support equality comparison', () {
      // Arrange
      final apartment1 = Apartment(
        id: '1',
        pavimentoId: 'pav1',
        towerId: 'tower1',
        number: '101',
        type: apartmentType,
        area: 85.5,
        bedrooms: 2,
        bathrooms: 2,
      );

      final apartment2 = Apartment(
        id: '1',
        pavimentoId: 'pav1',
        towerId: 'tower1',
        number: '101',
        type: apartmentType,
        area: 85.5,
        bedrooms: 2,
        bathrooms: 2,
      );

      final apartment3 = Apartment(
        id: '2',
        pavimentoId: 'pav2',
        towerId: 'tower2',
        number: '201',
        type: apartmentType,
        area: 100.0,
        bedrooms: 3,
        bathrooms: 2,
      );

      // Assert
      expect(apartment1, equals(apartment2));
      expect(apartment1, isNot(equals(apartment3)));
    });

    test('should support copyWith method', () {
      // Arrange
      final originalApartment = Apartment(
        id: '1',
        pavimentoId: 'pav1',
        towerId: 'tower1',
        number: '101',
        type: apartmentType,
        area: 85.5,
        bedrooms: 2,
        bathrooms: 2,
      );

      // Act
      final updatedApartment = originalApartment.copyWith(
        price: 275000.0,
        isAvailable: true,
        description: 'Apartamento reformado',
      );

      // Assert
      expect(updatedApartment.id, originalApartment.id);
      expect(updatedApartment.number, originalApartment.number);
      expect(updatedApartment.price, 275000.0);
      expect(updatedApartment.isAvailable, isTrue);
      expect(updatedApartment.description, 'Apartamento reformado');
      expect(updatedApartment.area, originalApartment.area);
      expect(updatedApartment.bedrooms, originalApartment.bedrooms);
    });

    test('should handle default values correctly', () {
      // Arrange & Act
      final apartmentMinimal = Apartment(
        id: '1',
        pavimentoId: 'pav1',
        towerId: 'tower1',
        number: '101',
        type: apartmentType,
        area: 85.5,
        bedrooms: 2,
        bathrooms: 2,
      );

      // Assert
      expect(apartmentMinimal.description, isNull);
      expect(apartmentMinimal.price, isNull);
      expect(apartmentMinimal.imageUrls, isNull);
      expect(apartmentMinimal.coordinates, isNull);
      expect(apartmentMinimal.isAvailable, isFalse);
      expect(apartmentMinimal.isSynced, isFalse);
    });

    test('should validate apartment number format', () {
      // Arrange & Act
      final apartments = [
        Apartment(
          id: '1',
          pavimentoId: 'pav1',
          towerId: 'tower1',
          number: '101',
          type: apartmentType,
          area: 85.5,
          bedrooms: 2,
          bathrooms: 2,
        ),
        Apartment(
          id: '2',
          pavimentoId: 'pav1',
          towerId: 'tower1',
          number: 'A101',
          type: apartmentType,
          area: 85.5,
          bedrooms: 2,
          bathrooms: 2,
        ),
      ];

      // Assert
      expect(apartments[0].number, '101');
      expect(apartments[1].number, 'A101');
    });
  });
}