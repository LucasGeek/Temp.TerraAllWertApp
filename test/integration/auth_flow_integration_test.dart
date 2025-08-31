import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terra_allwert_app/main.dart' as app;
import 'package:terra_allwert_app/domain/usecases/login_usecase.dart';
import 'package:terra_allwert_app/domain/entities/auth_token.dart';
import 'package:terra_allwert_app/presentation/features/auth/presentation/providers/auth_provider.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow Integration Tests', () {
    late MockLoginUseCase mockLoginUseCase;

    setUp(() {
      mockLoginUseCase = MockLoginUseCase();
    });

    testWidgets('should complete login flow successfully', (tester) async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      
      final authToken = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_123',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        tokenType: 'Bearer',
      );

      when(() => mockLoginUseCase(email: email, password: password))
          .thenAnswer((_) async => authToken);

      // Act - Start app with mocked dependencies
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: app.TerraAllwertApp(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Assert - Should see login screen
      expect(find.text('Terra Allwert'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);

      // Act - Enter credentials
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, email);
      await tester.enterText(passwordField, password);
      await tester.pumpAndSettle();

      // Act - Submit login
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert - Login use case should be called
      verify(() => mockLoginUseCase(email: email, password: password)).called(1);
    });

    testWidgets('should show validation errors for invalid input', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: app.TerraAllwertApp(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Act - Submit empty form
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert - Should show validation errors
      expect(find.text('Email é obrigatório'), findsOneWidget);
      expect(find.text('Senha é obrigatória'), findsOneWidget);

      // Verify login use case was not called
      verifyNever(() => mockLoginUseCase(email: any(named: 'email'), password: any(named: 'password')));
    });

    testWidgets('should show error message on login failure', (tester) async {
      // Arrange
      const email = 'invalid@example.com';
      const password = 'wrongpassword';
      const errorMessage = 'Invalid credentials';

      when(() => mockLoginUseCase(email: email, password: password))
          .thenThrow(Exception(errorMessage));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: app.TerraAllwertApp(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Act - Enter invalid credentials
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, email);
      await tester.enterText(passwordField, password);
      await tester.pumpAndSettle();

      // Act - Submit login
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert - Should show error message
      expect(find.textContaining(errorMessage), findsOneWidget);
      
      // Verify login use case was called but failed
      verify(() => mockLoginUseCase(email: email, password: password)).called(1);
    });

    testWidgets('should toggle password visibility', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: app.TerraAllwertApp(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Act - Enter password
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Act - Toggle visibility
      final visibilityButton = find.byIcon(Icons.visibility);
      expect(visibilityButton, findsOneWidget);
      
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // Assert - Should show visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);
    });

    testWidgets('should show loading indicator during login', (tester) async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';

      // Create a delayed response to simulate loading
      when(() => mockLoginUseCase(email: email, password: password))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
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
          child: app.TerraAllwertApp(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Act - Enter credentials and submit
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, email);
      await tester.enterText(passwordField, password);
      
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      
      // Pump once to trigger the loading state
      await tester.pump();

      // Assert - Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for the async operation to complete
      await tester.pumpAndSettle();
    });

    testWidgets('should validate email format', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
          ],
          child: app.TerraAllwertApp(),
        ),
      );
      
      await tester.pumpAndSettle();

      // Act - Enter invalid email format
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(emailField, 'invalid-email');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Act - Submit form
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Assert - Should show email validation error
      expect(find.text('Email inválido'), findsOneWidget);
      
      // Verify login use case was not called
      verifyNever(() => mockLoginUseCase(email: any(named: 'email'), password: any(named: 'password')));
    });
  });
}