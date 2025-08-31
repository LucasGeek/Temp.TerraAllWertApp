/// Enum para tipos de apresentação de menu
enum MenuPresentationType {
  standard('Menu Padrão', 'Apresentação padrão com carrossel de imagens'),
  pinMap('Menu com Pins', 'Apresentação de mapa com pins interativos'),
  floorPlan('Menu Pavimento', 'Apresentação de planta de pavimento');

  const MenuPresentationType(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Converte string para enum
  static MenuPresentationType fromString(String value) {
    return MenuPresentationType.values.firstWhere(
      (type) => type.displayName == value,
      orElse: () => MenuPresentationType.standard,
    );
  }

  /// Lista de todos os tipos disponíveis
  static List<String> get displayNames {
    return MenuPresentationType.values.map((type) => type.displayName).toList();
  }
}