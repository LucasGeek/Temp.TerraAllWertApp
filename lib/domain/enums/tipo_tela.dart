/// Enum para tipos de tela/apresentação conforme novas regras
enum TipoTela {
  standard('Padrão', 'Apresentação padrão com carrossel de imagens'),
  pinMap('Menu com Pins', 'Apresentação de mapa com pins interativos'),
  floorPlan('Menu Pavimento', 'Apresentação de planta de pavimento');

  const TipoTela(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Converte string para enum
  static TipoTela fromString(String value) {
    return TipoTela.values.firstWhere(
      (type) => type.displayName == value,
      orElse: () => TipoTela.standard,
    );
  }

  /// Lista de todos os tipos disponíveis
  static List<String> get displayNames {
    return TipoTela.values.map((type) => type.displayName).toList();
  }
}