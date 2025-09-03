/// Classe utilitária para validações de formulário
class FormValidators {
  // Regex para validação de email
  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  
  // Regex para validação de telefone brasileiro
  static final _phoneRegex = RegExp(r'^\(\d{2}\)\s?\d{4,5}-?\d{4}$');

  /// Valida se o campo é obrigatório
  static String? required(String? value, {String fieldName = 'Campo'}) {
    if (value?.trim().isEmpty ?? true) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  /// Valida formato de email
  static String? email(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Email é obrigatório';
    }
    
    final trimmed = value!.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Email inválido';
    }
    return null;
  }

  /// Valida comprimento mínimo da senha
  static String? password(String? value, {int minLength = 6}) {
    if (value?.isEmpty ?? true) {
      return 'Senha é obrigatória';
    }
    if (value!.length < minLength) {
      return 'Senha deve ter pelo menos $minLength caracteres';
    }
    return null;
  }

  /// Valida se duas senhas são iguais
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value?.isEmpty ?? true) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != originalPassword) {
      return 'Senhas não coincidem';
    }
    return null;
  }

  /// Valida comprimento mínimo
  static String? minLength(String? value, int min, {String fieldName = 'Campo'}) {
    if (value?.isEmpty ?? true) {
      return '$fieldName é obrigatório';
    }
    if (value!.length < min) {
      return '$fieldName deve ter pelo menos $min caracteres';
    }
    return null;
  }

  /// Valida comprimento máximo
  static String? maxLength(String? value, int max, {String fieldName = 'Campo'}) {
    if (value != null && value.length > max) {
      return '$fieldName deve ter no máximo $max caracteres';
    }
    return null;
  }

  /// Valida range de comprimento
  static String? lengthRange(String? value, int min, int max, {String fieldName = 'Campo'}) {
    if (value?.isEmpty ?? true) {
      return '$fieldName é obrigatório';
    }
    if (value!.length < min || value.length > max) {
      return '$fieldName deve ter entre $min e $max caracteres';
    }
    return null;
  }

  /// Valida números inteiros
  static String? integer(String? value, {String fieldName = 'Número'}) {
    if (value?.isEmpty ?? true) {
      return '$fieldName é obrigatório';
    }
    if (int.tryParse(value!) == null) {
      return '$fieldName deve ser um número inteiro válido';
    }
    return null;
  }

  /// Valida números decimais
  static String? decimal(String? value, {String fieldName = 'Número'}) {
    if (value?.isEmpty ?? true) {
      return '$fieldName é obrigatório';
    }
    if (double.tryParse(value!) == null) {
      return '$fieldName deve ser um número válido';
    }
    return null;
  }

  /// Valida telefone brasileiro
  static String? phone(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Telefone é obrigatório';
    }
    if (!_phoneRegex.hasMatch(value!)) {
      return 'Telefone inválido. Use o formato (XX) XXXX-XXXX';
    }
    return null;
  }

  /// Valida CEP brasileiro
  static String? cep(String? value) {
    if (value?.isEmpty ?? true) {
      return 'CEP é obrigatório';
    }
    final cepNumbers = value!.replaceAll(RegExp(r'[^\d]'), '');
    if (cepNumbers.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }
    return null;
  }

  /// Valida CPF brasileiro
  static String? cpf(String? value) {
    if (value?.isEmpty ?? true) {
      return 'CPF é obrigatório';
    }
    
    final cpfNumbers = value!.replaceAll(RegExp(r'[^\d]'), '');
    if (cpfNumbers.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    // Validação básica de CPF
    if (!_isValidCPF(cpfNumbers)) {
      return 'CPF inválido';
    }
    return null;
  }

  /// Valida CNPJ brasileiro
  static String? cnpj(String? value) {
    if (value?.isEmpty ?? true) {
      return 'CNPJ é obrigatório';
    }
    
    final cnpjNumbers = value!.replaceAll(RegExp(r'[^\d]'), '');
    if (cnpjNumbers.length != 14) {
      return 'CNPJ deve ter 14 dígitos';
    }

    // Validação básica de CNPJ
    if (!_isValidCNPJ(cnpjNumbers)) {
      return 'CNPJ inválido';
    }
    return null;
  }

  /// Combina múltiplos validadores
  static String? combine(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Validação condicional
  static String? Function(String?) when(bool condition, String? Function(String?) validator) {
    return (String? value) {
      if (condition) {
        return validator(value);
      }
      return null;
    };
  }

  // Métodos auxiliares privados
  static bool _isValidCPF(String cpf) {
    if (cpf.length != 11) return false;
    
    // Verifica se todos os dígitos são iguais
    if (cpf == cpf[0] * 11) return false;

    // Calcula primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit >= 10) firstDigit = 0;

    // Calcula segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit >= 10) secondDigit = 0;

    return int.parse(cpf[9]) == firstDigit && int.parse(cpf[10]) == secondDigit;
  }

  static bool _isValidCNPJ(String cnpj) {
    if (cnpj.length != 14) return false;
    
    // Verifica se todos os dígitos são iguais
    if (cnpj == cnpj[0] * 14) return false;

    // Calcula primeiro dígito verificador
    final weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * weights1[i];
    }
    int firstDigit = sum % 11;
    firstDigit = firstDigit < 2 ? 0 : 11 - firstDigit;

    // Calcula segundo dígito verificador
    final weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * weights2[i];
    }
    int secondDigit = sum % 11;
    secondDigit = secondDigit < 2 ? 0 : 11 - secondDigit;

    return int.parse(cnpj[12]) == firstDigit && int.parse(cnpj[13]) == secondDigit;
  }
}

/// Extensão para facilitar o uso de validadores
extension FormValidatorExtension on String? {
  String? get isRequired => FormValidators.required(this);
  String? get isEmail => FormValidators.email(this);
  String? get isPassword => FormValidators.password(this);
  String? get isPhone => FormValidators.phone(this);
  String? get isCPF => FormValidators.cpf(this);
  String? get isCNPJ => FormValidators.cnpj(this);
  String? get isCEP => FormValidators.cep(this);
  
  String? isMinLength(int min, {String fieldName = 'Campo'}) => 
      FormValidators.minLength(this, min, fieldName: fieldName);
  
  String? isMaxLength(int max, {String fieldName = 'Campo'}) => 
      FormValidators.maxLength(this, max, fieldName: fieldName);
      
  String? isLengthRange(int min, int max, {String fieldName = 'Campo'}) => 
      FormValidators.lengthRange(this, min, max, fieldName: fieldName);
}