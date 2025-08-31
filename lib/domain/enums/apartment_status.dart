/// Enum para status de apartamentos
enum ApartmentStatus {
  available('Disponível', 'Apartamento disponível para venda'),
  sold('Vendido', 'Apartamento já vendido');

  const ApartmentStatus(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Converte string para enum
  static ApartmentStatus fromString(String value) {
    return ApartmentStatus.values.firstWhere(
      (status) => status.displayName == value,
      orElse: () => ApartmentStatus.available,
    );
  }
}