import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:terra_allwert_app/domain/entities/auth_token.dart';
import 'package:terra_allwert_app/domain/entities/user.dart';
import 'package:terra_allwert_app/infra/graphql/auth_service.dart';
import 'package:terra_allwert_app/infra/graphql/graphql_client.dart';

class MockGraphQLClientService extends Mock implements GraphQLClientService {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

class FakeMutationOptions extends Fake implements MutationOptions {}
class FakeQueryOptions extends Fake implements QueryOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMutationOptions());
    registerFallbackValue(FakeQueryOptions());
  });
  late GraphQLAuthService authService;
  late MockGraphQLClientService mockClient;
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockClient = MockGraphQLClientService();
    mockStorage = MockSecureStorageService();
    authService = GraphQLAuthService(
      client: mockClient,
      storage: mockStorage,
    );
  });

  group('GraphQLAuthService', () {
    group('login', () {
      const email = 'test@example.com';
      const password = 'password123';
      
      final mockLoginResponse = QueryResult(
        data: {
          'login': {
            'token': 'access_token_123',
            'refreshToken': 'refresh_token_123',
            'expiresAt': '2024-12-31T23:59:59Z',
            'user': {
              'id': '1',
              'email': email,
              'name': 'Test User',
              'avatar': null,
              'role': {
                'id': '1',
                'name': 'User',
                'code': 'USER',
                'permissions': [],
              }
            }
          }
        },
        source: QueryResultSource.network,
        options: QueryOptions(document: gql('')),
      );

      test('should return auth token on successful login', () async {
        // Arrange
        when(() => mockClient.mutate(any())).thenAnswer((_) async => mockLoginResponse);
        when(() => mockStorage.setTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});

        // Act
        final result = await authService.login(email: email, password: password);

        // Assert
        expect(result, isA<AuthToken>());
        expect(result.accessToken, 'access_token_123');
        expect(result.refreshToken, 'refresh_token_123');
        expect(result.tokenType, 'Bearer');
        
        verify(() => mockStorage.setTokens(
          accessToken: 'access_token_123',
          refreshToken: 'refresh_token_123',
        )).called(1);
      });

      test('should throw exception on login failure', () async {
        // Arrange
        final errorResponse = QueryResult(
          data: null,
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(message: 'Invalid credentials')
            ],
          ),
        );
        when(() => mockClient.mutate(any())).thenAnswer((_) async => errorResponse);

        // Act & Assert
        expect(
          () async => await authService.login(email: email, password: password),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('signup', () {
      const email = 'test@example.com';
      const password = 'password123';
      const name = 'Test User';
      
      final mockSignupResponse = QueryResult(
        data: {
          'signup': {
            'token': 'access_token_123',
            'refreshToken': 'refresh_token_123',
            'expiresAt': '2024-12-31T23:59:59Z',
            'user': {
              'id': '1',
              'email': email,
              'name': name,
              'avatar': null,
              'role': {
                'id': '1',
                'name': 'User',
                'code': 'USER',
              }
            }
          }
        },
        source: QueryResultSource.network,
        options: QueryOptions(document: gql('')),
      );

      test('should return auth token on successful signup', () async {
        // Arrange
        when(() => mockClient.mutate(any())).thenAnswer((_) async => mockSignupResponse);
        when(() => mockStorage.setTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        )).thenAnswer((_) async {});

        // Act
        final result = await authService.signup(
          email: email,
          password: password,
          name: name,
        );

        // Assert
        expect(result, isA<AuthToken>());
        expect(result.accessToken, 'access_token_123');
        expect(result.refreshToken, 'refresh_token_123');
        
        verify(() => mockStorage.setTokens(
          accessToken: 'access_token_123',
          refreshToken: 'refresh_token_123',
        )).called(1);
      });
    });

    group('logout', () {
      test('should clear tokens on logout', () async {
        // Arrange
        final mockLogoutResponse = QueryResult(
          data: {'logout': {'success': true}},
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );
        when(() => mockClient.mutate(any())).thenAnswer((_) async => mockLogoutResponse);
        when(() => mockStorage.clearTokens()).thenAnswer((_) async {});
        when(() => mockClient.clearCache()).thenAnswer((_) async {});

        // Act
        await authService.logout();

        // Assert
        verify(() => mockStorage.clearTokens()).called(1);
        verify(() => mockClient.clearCache()).called(1);
      });

      test('should clear tokens even if server logout fails', () async {
        // Arrange
        when(() => mockClient.mutate(any())).thenThrow(Exception('Network error'));
        when(() => mockStorage.clearTokens()).thenAnswer((_) async {});
        when(() => mockClient.clearCache()).thenAnswer((_) async {});

        // Act
        await authService.logout();

        // Assert
        verify(() => mockStorage.clearTokens()).called(1);
        verify(() => mockClient.clearCache()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return user when query succeeds', () async {
        // Arrange
        final mockUserResponse = QueryResult(
          data: {
            'currentUser': {
              'id': '1',
              'email': 'test@example.com',
              'name': 'Test User',
              'avatar': null,
              'role': {
                'id': '1',
                'name': 'User',
                'code': 'USER',
                'permissions': [],
              }
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );
        when(() => mockClient.query(any())).thenAnswer((_) async => mockUserResponse);

        // Act
        final result = await authService.getCurrentUser();

        // Assert
        expect(result, isA<User>());
        expect(result?.id, '1');
        expect(result?.email, 'test@example.com');
        expect(result?.name, 'Test User');
      });

      test('should return null when query fails', () async {
        // Arrange
        when(() => mockClient.query(any())).thenThrow(Exception('Network error'));

        // Act
        final result = await authService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    group('hasValidToken', () {
      test('should return true when token exists', () async {
        // Arrange
        when(() => mockStorage.getAccessToken()).thenAnswer((_) async => 'valid_token');

        // Act
        final result = await authService.hasValidToken();

        // Assert
        expect(result, true);
      });

      test('should return false when token is null', () async {
        // Arrange
        when(() => mockStorage.getAccessToken()).thenAnswer((_) async => null);

        // Act
        final result = await authService.hasValidToken();

        // Assert
        expect(result, false);
      });

      test('should return false when token is empty', () async {
        // Arrange
        when(() => mockStorage.getAccessToken()).thenAnswer((_) async => '');

        // Act
        final result = await authService.hasValidToken();

        // Assert
        expect(result, false);
      });
    });
  });
}