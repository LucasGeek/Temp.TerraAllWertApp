import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:terra_allwert_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Terra Allwert App Integration Tests', () {
    testWidgets('should load app and show login screen', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify login screen is displayed
      expect(find.text('Terra Allwert'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('should show validation errors for empty fields', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Try to login with empty fields
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Email é obrigatório'), findsOneWidget);
      expect(find.text('Senha é obrigatória'), findsOneWidget);
    });

    testWidgets('should show email validation error', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'invalid-email');

      // Enter valid password
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      await tester.enterText(passwordField, 'password123');

      // Try to login
      final loginButton = find.text('Entrar');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show email validation error
      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find password field
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      expect(passwordField, findsOneWidget);

      // Enter password
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Find visibility toggle button
      final visibilityToggle = find.byIcon(Icons.visibility);
      expect(visibilityToggle, findsOneWidget);

      // Tap to show password
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();

      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should handle app lifecycle', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate app going to background
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('routeUpdated', {
            'location': '/login',
            'state': null,
          }),
        ),
        (data) {},
      );

      await tester.pumpAndSettle();

      // App should still be responsive
      expect(find.text('Terra Allwert'), findsOneWidget);
    });
  });
}