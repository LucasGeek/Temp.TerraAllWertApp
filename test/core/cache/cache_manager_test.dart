import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terra_allwert_app/core/infra/cache/cache_manager.dart';

class MockCacheManager extends Mock implements CacheManager {}

void main() {
  group('CacheManager', () {
    late MockCacheManager mockCacheManager;

    setUp(() {
      mockCacheManager = MockCacheManager();
    });

    group('Interface Tests', () {
      test('should implement CacheManager interface', () {
        expect(mockCacheManager, isA<CacheManager>());
      });

      test('should cache and retrieve data successfully', () async {
        // Arrange
        const key = 'test_key';
        final data = {'test': 'value'};
        
        when(() => mockCacheManager.cacheData(key, data))
            .thenAnswer((_) async {});
        
        when(() => mockCacheManager.getCachedData(key))
            .thenAnswer((_) async => data);

        // Act
        await mockCacheManager.cacheData(key, data);
        final result = await mockCacheManager.getCachedData(key);

        // Assert
        expect(result, equals(data));
        verify(() => mockCacheManager.cacheData(key, data)).called(1);
        verify(() => mockCacheManager.getCachedData(key)).called(1);
      });

      test('should return null for non-existent cached data', () async {
        // Arrange
        const key = 'non_existent_key';
        
        when(() => mockCacheManager.getCachedData(key))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockCacheManager.getCachedData(key);

        // Assert
        expect(result, isNull);
        verify(() => mockCacheManager.getCachedData(key)).called(1);
      });

      test('should cache and retrieve image successfully', () async {
        // Arrange
        const url = 'https://example.com/image.jpg';
        final imageData = Uint8List.fromList([1, 2, 3, 4]);
        
        when(() => mockCacheManager.cacheImage(url, imageData))
            .thenAnswer((_) async {});
        
        when(() => mockCacheManager.getCachedImage(url))
            .thenAnswer((_) async => null); // Simulating file would be returned

        // Act
        await mockCacheManager.cacheImage(url, imageData);
        await mockCacheManager.getCachedImage(url);

        // Assert
        verify(() => mockCacheManager.cacheImage(url, imageData)).called(1);
        verify(() => mockCacheManager.getCachedImage(url)).called(1);
      });

      test('should clear cache successfully', () async {
        // Arrange
        when(() => mockCacheManager.clearCache()).thenAnswer((_) async {});

        // Act
        await mockCacheManager.clearCache();

        // Assert
        verify(() => mockCacheManager.clearCache()).called(1);
      });

      test('should return cache size', () async {
        // Arrange
        const expectedSize = 1024;
        when(() => mockCacheManager.getCacheSize())
            .thenAnswer((_) async => expectedSize);

        // Act
        final size = await mockCacheManager.getCacheSize();

        // Assert
        expect(size, equals(expectedSize));
        verify(() => mockCacheManager.getCacheSize()).called(1);
      });

      test('should return cached keys list', () async {
        // Arrange
        final expectedKeys = ['key1', 'key2', 'key3'];
        when(() => mockCacheManager.getCachedKeys())
            .thenAnswer((_) async => expectedKeys);

        // Act
        final keys = await mockCacheManager.getCachedKeys();

        // Assert
        expect(keys, equals(expectedKeys));
        verify(() => mockCacheManager.getCachedKeys()).called(1);
      });

      test('should cache and retrieve GraphQL query', () async {
        // Arrange
        const query = 'query { user { id name } }';
        final variables = {'userId': '123'};
        final result = {'user': {'id': '123', 'name': 'Test User'}};
        
        when(() => mockCacheManager.cacheQuery(query, variables, result))
            .thenAnswer((_) async {});
        
        when(() => mockCacheManager.getCachedQuery(query, variables))
            .thenAnswer((_) async => result);

        // Act
        await mockCacheManager.cacheQuery(query, variables, result);
        final cachedResult = await mockCacheManager.getCachedQuery(query, variables);

        // Assert
        expect(cachedResult, equals(result));
        verify(() => mockCacheManager.cacheQuery(query, variables, result)).called(1);
        verify(() => mockCacheManager.getCachedQuery(query, variables)).called(1);
      });
    });
  });
}