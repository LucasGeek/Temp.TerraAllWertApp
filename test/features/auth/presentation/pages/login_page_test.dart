import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terra_allwert_app/presentation/features/auth/presentation/pages/login_page.dart';
import 'package:terra_allwert_app/presentation/features/auth/presentation/providers/auth_provider.dart';
import 'package:terra_allwert_app/presentation/features/auth/domain/entities/auth_token.dart';
import 'package:terra_allwert_app/presentation/features/auth/domain/usecases/login_usecase.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  group('LoginPage Widget Tests', () {
    late MockLoginUseCase mockLoginUseCase;

    setUp(() {
      mockLoginUseCase = MockLoginUseCase();
    });

    testWidgets('should display login form with email and password fields', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act & Assert
      expect(find.text('Terra Allwert'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      
      // Check for email and password TextFormFields
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should show validation error for empty email', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Email é obrigatório'), findsOneWidget);
    });

    testWidgets('should show validation error for empty password', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act
      // Enter email only
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Senha é obrigatória'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email format', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, 'invalid-email');
      await tester.enterText(passwordField, 'password123');
      
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');
      
      // Find the visibility toggle icon
      final visibilityIcon = find.byIcon(Icons.visibility);
      expect(visibilityIcon, findsOneWidget);
      
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should call login use case with correct parameters', (tester) async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      
      final authToken = AuthToken(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        tokenType: 'Bearer',
      );

      when(() => mockLoginUseCase(email: email, password: password))
          .thenAnswer((_) async => authToken);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, email);
      await tester.enterText(passwordField, password);
      
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockLoginUseCase(email: email, password: password)).called(1);
    });

    testWidgets('should show loading indicator during login', (tester) async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';

      // Create a completer to control when the login completes
      when(() => mockLoginUseCase(email: email, password: password))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return AuthToken(
          accessToken: 'access_token',
          refreshToken: 'refresh_token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          tokenType: 'Bearer',
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, email);
      await tester.enterText(passwordField, password);
      
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pump(); // Trigger one frame

      // Assert - should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message on login failure', (tester) async {
      // Arrange
      const email = 'test@example.com';
      const password = 'wrongpassword';
      const errorMessage = 'Invalid credentials';

      when(() => mockLoginUseCase(email: email, password: password))
          .thenThrow(Exception(errorMessage));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, email);
      await tester.enterText(passwordField, password);
      
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining(errorMessage), findsOneWidget);
    });
  });
}