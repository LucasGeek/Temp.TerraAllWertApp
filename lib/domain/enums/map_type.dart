/// Enum para tipos de mapa
enum MapType {
  normal('Rua', 'Visualização padrão com ruas e nomes'),
  satellite('Satélite', 'Vista de satélite'),
  hybrid('Híbrido', 'Combinação de satélite com ruas e nomes');

  const MapType(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Converte string para enum
  static MapType fromString(String value) {
    return MapType.values.firstWhere(
      (type) => type.displayName == value,
      orElse: () => MapType.normal,
    );
  }
}