/// Enum para ambientes da aplicação
enum Environment {
  development('development', 'Ambiente de desenvolvimento'),
  staging('staging', 'Ambiente de teste'),
  production('production', 'Ambiente de produção');

  const Environment(this.value, this.description);
  
  final String value;
  final String description;

  /// Converte string para enum
  static Environment fromString(String value) {
    return Environment.values.firstWhere(
      (env) => env.value == value,
      orElse: () => Environment.development,
    );
  }

  /// Verifica se é ambiente de desenvolvimento
  bool get isDevelopment => this == Environment.development;
  
  /// Verifica se é ambiente de produção
  bool get isProduction => this == Environment.production;
  
  /// Verifica se é ambiente de teste
  bool get isStaging => this == Environment.staging;
}