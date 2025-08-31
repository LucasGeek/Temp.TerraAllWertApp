/// Enum para tipos de marcadores na planta
enum MarkerType {
  existingApartment('Apartamento Existente', 'Marcador para apartamento já cadastrado'),
  newApartment('Novo Apartamento', 'Marcador para novo apartamento');

  const MarkerType(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Converte string para enum
  static MarkerType fromString(String value) {
    return MarkerType.values.firstWhere(
      (type) => type.displayName == value,
      orElse: () => MarkerType.newApartment,
    );
  }
}