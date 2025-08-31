/// Enum para tipos de conteúdo dos pins
enum PinContentType {
  singleImage('Imagem Única', 'Exibe uma única imagem'),
  carousel('Carrossel', 'Exibe múltiplas imagens em carrossel');

  const PinContentType(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Converte string para enum
  static PinContentType fromString(String value) {
    return PinContentType.values.firstWhere(
      (type) => type.displayName == value,
      orElse: () => PinContentType.singleImage,
    );
  }
}