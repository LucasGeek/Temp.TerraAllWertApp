/// Enum para posição solar dos apartamentos
enum SunPosition {
  north('Norte', 'Posição solar Norte'),
  south('Sul', 'Posição solar Sul'),
  east('Leste', 'Posição solar Leste'),
  west('Oeste', 'Posição solar Oeste'),
  northeast('Nordeste', 'Posição solar Nordeste'),
  northwest('Noroeste', 'Posição solar Noroeste'),
  southeast('Sudeste', 'Posição solar Sudeste'),
  southwest('Sudoeste', 'Posição solar Sudoeste');

  const SunPosition(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Converte string para enum
  static SunPosition fromString(String value) {
    return SunPosition.values.firstWhere(
      (position) => position.displayName == value,
      orElse: () => SunPosition.north,
    );
  }
}