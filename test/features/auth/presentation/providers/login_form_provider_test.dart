import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terra_allwert_app/features/auth/presentation/providers/login_form_provider.dart';

void main() {
  group('LoginFormProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have initial state', () {
      final state = container.read(loginFormProvider);

      expect(state.email, equals(''));
      expect(state.password, equals(''));
      expect(state.obscurePassword, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.isValid, isFalse);
      expect(state.emailError, isNull);
      expect(state.passwordError, isNull);
      expect(state.submitError, isNull);
    });

    group('updateEmail', () {
      test('should update email and validate', () {
        final notifier = container.read(loginFormProvider.notifier);
        
        // Valid email
        notifier.updateEmail('test@example.com');
        
        var state = container.read(loginFormProvider);
        expect(state.email, equals('test@example.com'));
        expect(state.emailError, isNull);
        expect(state.isValid, isFalse); // Password still empty

        // Invalid email
        notifier.updateEmail('invalid');
        
        state = container.read(loginFormProvider);
        expect(state.email, equals('invalid'));
        expect(state.emailError, equals('Email inválido'));
        expect(state.isValid, isFalse);

        // Empty email
        notifier.updateEmail('');
        
        state = container.read(loginFormProvider);
        expect(state.email, equals(''));
        expect(state.emailError, equals('Email é obrigatório'));
        expect(state.isValid, isFalse);
      });
    });

    group('updatePassword', () {
      test('should update password and validate', () {
        final notifier = container.read(loginFormProvider.notifier);
        
        // Valid password
        notifier.updatePassword('password123');
        
        var state = container.read(loginFormProvider);
        expect(state.password, equals('password123'));
        expect(state.passwordError, isNull);
        expect(state.isValid, isFalse); // Email still empty

        // Short password
        notifier.updatePassword('123');
        
        state = container.read(loginFormProvider);
        expect(state.password, equals('123'));
        expect(state.passwordError, equals('Senha deve ter pelo menos 6 caracteres'));
        expect(state.isValid, isFalse);

        // Empty password
        notifier.updatePassword('');
        
        state = container.read(loginFormProvider);
        expect(state.password, equals(''));
        expect(state.passwordError, equals('Senha é obrigatória'));
        expect(state.isValid, isFalse);
      });
    });

    test('should be valid when both email and password are valid', () {
      final notifier = container.read(loginFormProvider.notifier);
      
      notifier.updateEmail('test@example.com');
      notifier.updatePassword('password123');
      
      final state = container.read(loginFormProvider);
      expect(state.isValid, isTrue);
    });

    test('should toggle password visibility', () {
      final notifier = container.read(loginFormProvider.notifier);
      
      expect(container.read(loginFormProvider).obscurePassword, isFalse);
      
      notifier.togglePasswordVisibility();
      expect(container.read(loginFormProvider).obscurePassword, isTrue);
      
      notifier.togglePasswordVisibility();
      expect(container.read(loginFormProvider).obscurePassword, isFalse);
    });

    group('submission state', () {
      test('should handle start submitting', () {
        final notifier = container.read(loginFormProvider.notifier);
        
        // Set an error first to verify it gets cleared
        notifier.submitError('Previous error');
        notifier.startSubmitting();
        
        final state = container.read(loginFormProvider);
        expect(state.isSubmitting, isTrue);
        expect(state.submitError, isNull);
      });

      test('should handle submit success', () {
        final notifier = container.read(loginFormProvider.notifier);
        
        notifier.startSubmitting();
        notifier.submitSuccess();
        
        final state = container.read(loginFormProvider);
        expect(state.isSubmitting, isFalse);
        expect(state.submitError, isNull);
      });

      test('should handle submit error', () {
        final notifier = container.read(loginFormProvider.notifier);
        
        notifier.startSubmitting();
        notifier.submitError('Login failed');
        
        final state = container.read(loginFormProvider);
        expect(state.isSubmitting, isFalse);
        expect(state.submitError, equals('Login failed'));
      });
    });

    test('should validate entire form', () {
      final notifier = container.read(loginFormProvider.notifier);
      
      // Set invalid values without validation
      notifier.updateEmail('test@example.com');
      notifier.updatePassword('123'); // Too short
      
      // Force validation
      notifier.validate();
      
      final state = container.read(loginFormProvider);
      expect(state.emailError, isNull);
      expect(state.passwordError, equals('Senha deve ter pelo menos 6 caracteres'));
      expect(state.isValid, isFalse);
    });

    test('should clear form', () {
      final notifier = container.read(loginFormProvider.notifier);
      
      // Set some values
      notifier.updateEmail('test@example.com');
      notifier.updatePassword('password123');
      notifier.togglePasswordVisibility();
      notifier.submitError('Some error');
      
      // Clear form
      notifier.clear();
      
      final state = container.read(loginFormProvider);
      expect(state.email, equals(''));
      expect(state.password, equals(''));
      expect(state.obscurePassword, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.isValid, isFalse);
      expect(state.emailError, isNull);
      expect(state.passwordError, isNull);
      expect(state.submitError, isNull);
    });

    group('derived providers', () {
      test('isLoginFormValidProvider should reflect form validity', () {
        final notifier = container.read(loginFormProvider.notifier);
        
        expect(container.read(isLoginFormValidProvider), isFalse);
        
        notifier.updateEmail('test@example.com');
        notifier.updatePassword('password123');
        
        expect(container.read(isLoginFormValidProvider), isTrue);
        
        notifier.updateEmail('invalid');
        
        expect(container.read(isLoginFormValidProvider), isFalse);
      });

      test('isLoginFormSubmittingProvider should reflect submission state', () {
        final notifier = container.read(loginFormProvider.notifier);
        
        expect(container.read(isLoginFormSubmittingProvider), isFalse);
        
        notifier.startSubmitting();
        expect(container.read(isLoginFormSubmittingProvider), isTrue);
        
        notifier.submitSuccess();
        expect(container.read(isLoginFormSubmittingProvider), isFalse);
      });

      test('loginFormSubmitErrorProvider should reflect error state', () {
        final notifier = container.read(loginFormProvider.notifier);
        
        expect(container.read(loginFormSubmitErrorProvider), isNull);
        
        notifier.submitError('Login failed');
        expect(container.read(loginFormSubmitErrorProvider), equals('Login failed'));
        
        notifier.startSubmitting();
        expect(container.read(loginFormSubmitErrorProvider), isNull);
      });
    });
  });
}