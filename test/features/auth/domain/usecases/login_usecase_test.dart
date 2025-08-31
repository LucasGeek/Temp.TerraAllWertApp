import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terra_allwert_app/presentation/features/auth/domain/entities/auth_token.dart';
import 'package:terra_allwert_app/presentation/features/auth/domain/repositories/auth_repository.dart';
import 'package:terra_allwert_app/presentation/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('LoginUseCase', () {
    late LoginUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = LoginUseCase(mockRepository);
    });

    test('should return AuthToken when login is successful', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      
      final authToken = AuthToken(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        tokenType: 'Bearer',
      );

      when(() => mockRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => authToken);

      // Act
      final result = await useCase(email: email, password: password);

      // Assert
      expect(result, equals(authToken));
      verify(() => mockRepository.login(
        email: email,
        password: password,
      )).called(1);
    });

    test('should throw ArgumentError when email is empty', () async {
      // Act & Assert
      expect(
        () => useCase(email: '', password: 'password123'),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Email não pode estar vazio',
        )),
      );
    });

    test('should throw ArgumentError when password is empty', () async {
      // Act & Assert
      expect(
        () => useCase(email: 'test@example.com', password: ''),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Senha não pode estar vazia',
        )),
      );
    });

    test('should trim email before calling repository', () async {
      // Arrange
      const email = '  test@example.com  ';
      const password = 'password123';
      
      final authToken = AuthToken(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        tokenType: 'Bearer',
      );

      when(() => mockRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => authToken);

      // Act
      await useCase(email: email, password: password);

      // Assert
      verify(() => mockRepository.login(
        email: 'test@example.com', // Email should be trimmed
        password: password,
      )).called(1);
    });
  });
}