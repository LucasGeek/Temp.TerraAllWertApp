import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:terra_allwert_app/data/repositories/auth_repository_impl.dart';
import 'package:terra_allwert_app/domain/entities/auth_token.dart';
import 'package:terra_allwert_app/domain/entities/user.dart';
import 'package:terra_allwert_app/infra/graphql/auth_service.dart';

class MockGraphQLAuthService extends Mock implements GraphQLAuthService {}

void main() {
  late AuthRepositoryImpl repository;
  late MockGraphQLAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockGraphQLAuthService();
    repository = AuthRepositoryImpl(authService: mockAuthService);
  });

  tearDown(() {
    repository.dispose();
  });

  group('AuthRepositoryImpl', () {
    group('login', () {
      const email = 'test@example.com';
      const password = 'password123';
      
      final mockToken = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_123',
        expiresAt: DateTime(2024, 12, 31),
        tokenType: 'Bearer',
      );

      final mockUser = User(
        id: '1',
        email: email,
        name: 'Test User',
        role: UserRole(id: '1', name: 'User', code: 'USER'),
      );

      test('should return auth token and update streams on successful login', () async {
        // Arrange
        when(() => mockAuthService.login(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockToken);
        when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);

        // Act
        final result = await repository.login(email: email, password: password);

        // Assert
        expect(result, equals(mockToken));
        
        // Verify service was called
        verify(() => mockAuthService.login(email: email, password: password)).called(1);
        verify(() => mockAuthService.getCurrentUser()).called(1);
      });

      test('should update auth state stream to false on login failure', () async {
        // Arrange
        when(() => mockAuthService.login(
          email: email,
          password: password,
        )).thenThrow(Exception('Login failed'));

        // Act & Assert
        expect(
          () async => await repository.login(email: email, password: password),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('signup', () {
      const email = 'test@example.com';
      const password = 'password123';
      const name = 'Test User';
      
      final mockToken = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_123',
        expiresAt: DateTime(2024, 12, 31),
        tokenType: 'Bearer',
      );

      test('should return auth token on successful signup', () async {
        // Arrange
        when(() => mockAuthService.signup(
          email: email,
          password: password,
          name: name,
        )).thenAnswer((_) async => mockToken);
        when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => null);

        // Act
        final result = await repository.signup(
          email: email,
          password: password,
          name: name,
        );

        // Assert
        expect(result, equals(mockToken));
        verify(() => mockAuthService.signup(
          email: email,
          password: password,
          name: name,
        )).called(1);
      });
    });

    group('logout', () {
      test('should call auth service logout', () async {
        // Arrange
        when(() => mockAuthService.logout()).thenAnswer((_) async {});

        // Act
        await repository.logout();

        // Assert
        verify(() => mockAuthService.logout()).called(1);
      });
    });

    group('getCurrentUser', () {
      final mockUser = User(
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole(id: '1', name: 'User', code: 'USER'),
      );

      test('should return user from auth service', () async {
        // Arrange
        when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, equals(mockUser));
        verify(() => mockAuthService.getCurrentUser()).called(1);
      });

      test('should return null when auth service returns null', () async {
        // Arrange
        when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => null);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });

      test('should return null when auth service throws exception', () async {
        // Arrange
        when(() => mockAuthService.getCurrentUser()).thenThrow(Exception('Network error'));

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    group('isAuthenticated', () {
      test('should return true when auth service has valid token', () async {
        // Arrange
        when(() => mockAuthService.hasValidToken()).thenAnswer((_) async => true);

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result, true);
        verify(() => mockAuthService.hasValidToken()).called(1);
      });

      test('should return false when auth service has no valid token', () async {
        // Arrange
        when(() => mockAuthService.hasValidToken()).thenAnswer((_) async => false);

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result, false);
      });
    });

    group('refreshToken', () {
      final mockToken = AuthToken(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
        expiresAt: DateTime(2024, 12, 31),
        tokenType: 'Bearer',
      );

      test('should return refreshed token', () async {
        // Arrange
        when(() => mockAuthService.refreshToken()).thenAnswer((_) async => mockToken);

        // Act
        final result = await repository.refreshToken('old_refresh_token');

        // Assert
        expect(result, equals(mockToken));
        verify(() => mockAuthService.refreshToken()).called(1);
      });

      test('should clear token and rethrow on refresh failure', () async {
        // Arrange
        when(() => mockAuthService.refreshToken()).thenThrow(Exception('Refresh failed'));
        when(() => mockAuthService.logout()).thenAnswer((_) async {});

        // Act & Assert
        expect(
          () async => await repository.refreshToken('old_refresh_token'),
          throwsA(isA<Exception>()),
        );
        verify(() => mockAuthService.logout()).called(1);
      });
    });

    group('stream tests', () {
      test('should emit auth state changes', () async {
        // Arrange
        when(() => mockAuthService.login(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => AuthToken(
          accessToken: 'token',
          refreshToken: 'refresh',
          expiresAt: DateTime(2024, 12, 31),
          tokenType: 'Bearer',
        ));
        when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => null);

        // Act & Assert
        expectLater(
          repository.watchAuthState(),
          emitsInOrder([true]),
        );

        await repository.login(email: 'test@example.com', password: 'password123');
      });

      test('should emit user changes', () async {
        // Arrange
        final mockUser = User(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole(id: '1', name: 'User', code: 'USER'),
        );
        when(() => mockAuthService.login(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => AuthToken(
          accessToken: 'token',
          refreshToken: 'refresh',
          expiresAt: DateTime(2024, 12, 31),
          tokenType: 'Bearer',
        ));
        when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);

        // Act & Assert
        expectLater(
          repository.watchCurrentUser(),
          emitsInOrder([mockUser]),
        );

        await repository.login(email: 'test@example.com', password: 'password123');
      });
    });
  });
}