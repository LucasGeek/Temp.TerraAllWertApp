/// Enum para tipos de menu conforme novas regras
enum MenuPresentationType {
  padrao('Padrão', 'Menu padrão com apresentação de conteúdo'),
  comSubmenu('Com Submenu', 'Menu que pode ter submenus aninhados');

  const MenuPresentationType(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Converte string para enum
  static MenuPresentationType fromString(String value) {
    return MenuPresentationType.values.firstWhere(
      (type) => type.displayName == value,
      orElse: () => MenuPresentationType.padrao,
    );
  }

  /// Lista de todos os tipos disponíveis
  static List<String> get displayNames {
    return MenuPresentationType.values.map((type) => type.displayName).toList();
  }
}