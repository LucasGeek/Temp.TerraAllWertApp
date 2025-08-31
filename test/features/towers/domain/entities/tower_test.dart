import 'package:flutter_test/flutter_test.dart';
import 'package:terra_allwert_app/features/towers/domain/entities/tower.dart';

void main() {
  group('Tower Entity', () {
    test('should create a Tower with required parameters', () {
      // Arrange
      final tower = Tower(
        id: '1',
        name: 'Torre A',
        description: 'Descrição da Torre A',
        pavimentos: [],
      );

      // Assert
      expect(tower.id, equals('1'));
      expect(tower.name, equals('Torre A'));
      expect(tower.description, equals('Descrição da Torre A'));
      expect(tower.pavimentos, isEmpty);
      expect(tower.isSynced, isFalse);
      expect(tower.address, isNull);
      expect(tower.imageUrl, isNull);
    });

    test('should create Tower from JSON', () {
      // Arrange
      final json = {
        'id': '1',
        'name': 'Torre A',
        'description': 'Descrição da Torre A',
        'address': 'Rua A, 123',
        'imageUrl': 'https://example.com/image.jpg',
        'pavimentos': [],
        'createdAt': '2023-01-01T00:00:00Z',
        'updatedAt': '2023-01-01T00:00:00Z',
        'isSynced': true,
      };

      // Act
      final tower = Tower.fromJson(json);

      // Assert
      expect(tower.id, equals('1'));
      expect(tower.name, equals('Torre A'));
      expect(tower.address, equals('Rua A, 123'));
      expect(tower.imageUrl, equals('https://example.com/image.jpg'));
      expect(tower.isSynced, isTrue);
    });

    test('should convert Tower to JSON', () {
      // Arrange
      final tower = Tower(
        id: '1',
        name: 'Torre A',
        description: 'Descrição da Torre A',
        pavimentos: [],
        isSynced: true,
      );

      // Act
      final json = tower.toJson();

      // Assert
      expect(json['id'], equals('1'));
      expect(json['name'], equals('Torre A'));
      expect(json['description'], equals('Descrição da Torre A'));
      expect(json['isSynced'], isTrue);
      expect(json['pavimentos'], isEmpty);
    });

    test('should support equality comparison', () {
      // Arrange
      final tower1 = Tower(
        id: '1',
        name: 'Torre A',
        description: 'Descrição da Torre A',
        pavimentos: [],
      );

      final tower2 = Tower(
        id: '1',
        name: 'Torre A',
        description: 'Descrição da Torre A',
        pavimentos: [],
      );

      // Assert
      expect(tower1, equals(tower2));
      expect(tower1.hashCode, equals(tower2.hashCode));
    });
  });
}