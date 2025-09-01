/// Enum para tipos de mapa
enum MapType {
  openStreet('OpenStreet', 'Mapa OpenStreet colaborativo (padrão)'),
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
      orElse: () => MapType.openStreet, // OpenStreet como padrão
    );
  }

  /// Serialização JSON - converte enum para string
  String toJson() => name;

  /// Desserialização JSON - converte string para enum
  static MapType fromJson(String json) {
    return MapType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => MapType.openStreet,
    );
  }
}