/// Enum para tipos de mapa do OpenStreetMap
enum MapType {
  openStreet('OpenStreet', 'Mapa OpenStreet colaborativo (padrão)'),
  satellite('Satélite', 'Vista de satélite'),
  terrain('Terreno', 'Vista topográfica do terreno');

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