import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:terra_allwert_app/domain/entities/auth_token.dart';
import 'package:terra_allwert_app/domain/entities/user.dart';
import 'package:terra_allwert_app/infra/graphql/smart_auth_service.dart';
import 'package:terra_allwert_app/data/repositories/auth_repository_impl.dart';
import 'package:terra_allwert_app/presentation/features/auth/presentation/pages/login_page.dart';

class MockSmartAuthService extends Mock implements SmartAuthService {}

void main() {
  late MockSmartAuthService mockAuthService;

  setUpAll(() {
    // Register fallback values if needed
  });

  setUp(() {
    mockAuthService = MockSmartAuthService();
  });

  group('Auth Integration Tests', () {
    testWidgets('should complete login flow successfully', (WidgetTester tester) async {
      // Arrange
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

      when(() => mockAuthService.login(
        email: email,
        password: password,
      )).thenAnswer((_) async => mockToken);
      when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);
      when(() => mockAuthService.hasValidToken()).thenAnswer((_) async => false);

      // Create app with mocked dependencies
      final app = ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepositoryImpl(authService: mockAuthService),
          ),
        ],
        child: MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.pumpWidget(app);

      // Act & Assert
      // Find email input field and enter email
      final emailField = find.byKey(Key('email_field'));
      expect(emailField, findsOneWidget);
      await tester.enterText(emailField, email);

      // Find password input field and enter password
      final passwordField = find.byKey(Key('password_field'));
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, password);

      // Find and tap login button
      final loginButton = find.byKey(Key('login_button'));
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);

      // Wait for async operations
      await tester.pumpAndSettle();

      // Verify that login was called
      verify(() => mockAuthService.login(email: email, password: password)).called(1);
      verify(() => mockAuthService.getCurrentUser()).called(1);
    });

    testWidgets('should handle login failure gracefully', (WidgetTester tester) async {
      // Arrange
      const email = 'test@example.com';
      const password = 'wrong_password';
      
      when(() => mockAuthService.login(
        email: email,
        password: password,
      )).thenThrow(Exception('Invalid credentials'));
      when(() => mockAuthService.hasValidToken()).thenAnswer((_) async => false);

      final app = ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            AuthRepositoryImpl(authService: mockAuthService),
          ),
        ],
        child: MaterialApp(
          home: LoginPage(),
        ),
      );

      await tester.pumpWidget(app);

      // Act
      await tester.enterText(find.byKey(Key('email_field')), email);
      await tester.enterText(find.byKey(Key('password_field')), password);
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockAuthService.login(email: email, password: password)).called(1);
      
      // Should show error state or stay on login page
      expect(find.byType(LoginPage), findsOneWidget);
    });

    group('Repository Integration', () {
      test('should properly integrate auth service with repository', () async {
        // Arrange
        final repository = AuthRepositoryImpl(authService: mockAuthService);
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

        when(() => mockAuthService.login(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockToken);
        when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);

        // Act
        final result = await repository.login(email: email, password: password);

        // Assert
        expect(result, equals(mockToken));
        verify(() => mockAuthService.login(email: email, password: password)).called(1);
        verify(() => mockAuthService.getCurrentUser()).called(1);

        // Cleanup
        repository.dispose();
      });

      test('should handle complete auth flow with streams', () async {
        // Arrange
        final repository = AuthRepositoryImpl(authService: mockAuthService);
        
        final mockToken = AuthToken(
          accessToken: 'token',
          refreshToken: 'refresh',
          expiresAt: DateTime(2024, 12, 31),
          tokenType: 'Bearer',
        );

        final mockUser = User(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole(id: '1', name: 'User', code: 'USER'),
        );

        when(() => mockAuthService.login(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockToken);
        when(() => mockAuthService.getCurrentUser()).thenAnswer((_) async => mockUser);
        when(() => mockAuthService.logout()).thenAnswer((_) async {});

        // Act & Assert
        // Test login flow
        expectLater(repository.watchAuthState(), emitsInOrder([true, false]));
        expectLater(repository.watchCurrentUser(), emitsInOrder([mockUser, null]));

        await repository.login(email: 'test@example.com', password: 'password123');
        await repository.logout();

        // Cleanup
        repository.dispose();
      });
    });
  });
}