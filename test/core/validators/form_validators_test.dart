import 'package:flutter_test/flutter_test.dart';
import 'package:terra_allwert_app/core/validators/form_validators.dart';

void main() {
  group('FormValidators', () {
    group('required', () {
      test('should return error for null value', () {
        expect(FormValidators.required(null), equals('Campo é obrigatório'));
      });

      test('should return error for empty string', () {
        expect(FormValidators.required(''), equals('Campo é obrigatório'));
      });

      test('should return error for whitespace string', () {
        expect(FormValidators.required('   '), equals('Campo é obrigatório'));
      });

      test('should return null for valid string', () {
        expect(FormValidators.required('valid'), isNull);
      });

      test('should use custom field name', () {
        expect(
          FormValidators.required('', fieldName: 'Nome'),
          equals('Nome é obrigatório'),
        );
      });
    });

    group('email', () {
      test('should return error for null/empty email', () {
        expect(FormValidators.email(null), equals('Email é obrigatório'));
        expect(FormValidators.email(''), equals('Email é obrigatório'));
      });

      test('should return error for invalid email format', () {
        expect(FormValidators.email('invalid'), equals('Email inválido'));
        expect(FormValidators.email('invalid@'), equals('Email inválido'));
        expect(FormValidators.email('invalid@domain'), equals('Email inválido'));
        expect(FormValidators.email('@domain.com'), equals('Email inválido'));
      });

      test('should return null for valid email', () {
        expect(FormValidators.email('test@example.com'), isNull);
        expect(FormValidators.email('user.name+tag@example.co.uk'), isNull);
        expect(FormValidators.email('test123@sub.domain.com'), isNull);
      });

      test('should handle whitespace in email', () {
        expect(FormValidators.email(' test@example.com '), isNull);
      });
    });

    group('password', () {
      test('should return error for null/empty password', () {
        expect(FormValidators.password(null), equals('Senha é obrigatória'));
        expect(FormValidators.password(''), equals('Senha é obrigatória'));
      });

      test('should return error for password below minimum length', () {
        expect(
          FormValidators.password('123'),
          equals('Senha deve ter pelo menos 6 caracteres'),
        );
        expect(
          FormValidators.password('ab', minLength: 8),
          equals('Senha deve ter pelo menos 8 caracteres'),
        );
      });

      test('should return null for valid password', () {
        expect(FormValidators.password('123456'), isNull);
        expect(FormValidators.password('strong_password123'), isNull);
      });
    });

    group('confirmPassword', () {
      test('should return error for empty confirmation', () {
        expect(
          FormValidators.confirmPassword('', 'password'),
          equals('Confirmação de senha é obrigatória'),
        );
      });

      test('should return error for non-matching passwords', () {
        expect(
          FormValidators.confirmPassword('password1', 'password2'),
          equals('Senhas não coincidem'),
        );
      });

      test('should return null for matching passwords', () {
        expect(FormValidators.confirmPassword('password', 'password'), isNull);
      });
    });

    group('minLength', () {
      test('should return error for empty value', () {
        expect(
          FormValidators.minLength('', 5),
          equals('Campo é obrigatório'),
        );
      });

      test('should return error for value below minimum', () {
        expect(
          FormValidators.minLength('abc', 5),
          equals('Campo deve ter pelo menos 5 caracteres'),
        );
      });

      test('should return null for valid length', () {
        expect(FormValidators.minLength('abcde', 5), isNull);
        expect(FormValidators.minLength('abcdef', 5), isNull);
      });
    });

    group('maxLength', () {
      test('should return null for null or empty value', () {
        expect(FormValidators.maxLength(null, 5), isNull);
        expect(FormValidators.maxLength('', 5), isNull);
      });

      test('should return error for value above maximum', () {
        expect(
          FormValidators.maxLength('abcdefgh', 5),
          equals('Campo deve ter no máximo 5 caracteres'),
        );
      });

      test('should return null for valid length', () {
        expect(FormValidators.maxLength('abc', 5), isNull);
        expect(FormValidators.maxLength('abcde', 5), isNull);
      });
    });

    group('integer', () {
      test('should return error for empty value', () {
        expect(FormValidators.integer(''), equals('Número é obrigatório'));
      });

      test('should return error for non-integer values', () {
        expect(
          FormValidators.integer('abc'),
          equals('Número deve ser um número inteiro válido'),
        );
        expect(
          FormValidators.integer('12.5'),
          equals('Número deve ser um número inteiro válido'),
        );
      });

      test('should return null for valid integers', () {
        expect(FormValidators.integer('123'), isNull);
        expect(FormValidators.integer('-456'), isNull);
        expect(FormValidators.integer('0'), isNull);
      });
    });

    group('decimal', () {
      test('should return error for empty value', () {
        expect(FormValidators.decimal(''), equals('Número é obrigatório'));
      });

      test('should return error for non-numeric values', () {
        expect(
          FormValidators.decimal('abc'),
          equals('Número deve ser um número válido'),
        );
      });

      test('should return null for valid numbers', () {
        expect(FormValidators.decimal('123'), isNull);
        expect(FormValidators.decimal('12.5'), isNull);
        expect(FormValidators.decimal('-45.67'), isNull);
      });
    });

    group('phone', () {
      test('should return error for empty phone', () {
        expect(FormValidators.phone(''), equals('Telefone é obrigatório'));
      });

      test('should return error for invalid phone format', () {
        expect(
          FormValidators.phone('123456789'),
          equals('Telefone inválido. Use o formato (XX) XXXX-XXXX'),
        );
        expect(
          FormValidators.phone('abc'),
          equals('Telefone inválido. Use o formato (XX) XXXX-XXXX'),
        );
      });

      test('should return null for valid phone formats', () {
        expect(FormValidators.phone('(11) 9999-9999'), isNull);
        expect(FormValidators.phone('(21) 98765-4321'), isNull);
      });
    });

    group('cpf', () {
      test('should return error for empty CPF', () {
        expect(FormValidators.cpf(''), equals('CPF é obrigatório'));
      });

      test('should return error for invalid CPF length', () {
        expect(FormValidators.cpf('123'), equals('CPF deve ter 11 dígitos'));
        expect(
          FormValidators.cpf('123.456.789-123'),
          equals('CPF deve ter 11 dígitos'),
        );
      });

      test('should return error for invalid CPF', () {
        expect(FormValidators.cpf('11111111111'), equals('CPF inválido'));
        expect(FormValidators.cpf('123.456.789-00'), equals('CPF inválido'));
      });

      // Note: Testing with a valid CPF would require implementing the full algorithm
      // For now, we're testing the format validation
    });

    group('combine', () {
      test('should return first validation error', () {
        final validators = [
          (String? value) => FormValidators.required(value),
          (String? value) => FormValidators.email(value),
        ];

        expect(
          FormValidators.combine('', validators),
          equals('Campo é obrigatório'),
        );

        expect(
          FormValidators.combine('invalid', validators),
          equals('Email inválido'),
        );
      });

      test('should return null when all validators pass', () {
        final validators = [
          (String? value) => FormValidators.required(value),
          (String? value) => FormValidators.email(value),
        ];

        expect(FormValidators.combine('test@example.com', validators), isNull);
      });
    });

    group('when', () {
      test('should apply validator when condition is true', () {
        final validator = FormValidators.when(
          true,
          FormValidators.required,
        );

        expect(validator(''), equals('Campo é obrigatório'));
      });

      test('should skip validator when condition is false', () {
        final validator = FormValidators.when(
          false,
          FormValidators.required,
        );

        expect(validator(''), isNull);
      });
    });
  });

  group('FormValidatorExtension', () {
    test('should provide convenient extension methods', () {
      expect(''.isRequired, equals('Campo é obrigatório'));
      expect('test@example.com'.isEmail, isNull);
      expect('invalid'.isEmail, equals('Email inválido'));
      expect('123456'.isPassword, isNull);
      expect('123'.isPassword, equals('Senha deve ter pelo menos 6 caracteres'));
      expect('ab'.isMinLength(5), equals('Campo deve ter pelo menos 5 caracteres'));
    });
  });
}