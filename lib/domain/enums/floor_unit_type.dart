/// Enum para tipos de unidades em plantas de pavimento
enum FloorUnitType {
  apartment('apartment', 'Apartamento'),
  elevator('elevator', 'Elevador'),
  stairs('stairs', 'Escadas'),
  common('common', 'Área Comum');

  const FloorUnitType(this.value, this.displayName);
  
  final String value;
  final String displayName;

  /// Converte string para enum
  static FloorUnitType fromString(String value) {
    return FloorUnitType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => FloorUnitType.apartment,
    );
  }
}