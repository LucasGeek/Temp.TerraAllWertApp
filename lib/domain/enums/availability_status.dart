import 'package:flutter/material.dart';

/// Enum para status de disponibilidade de unidades
enum AvailabilityStatus {
  available('Disponível', 'Unidade disponível para venda'),
  sold('Vendido', 'Unidade já vendida'),
  reserved('Reservado', 'Unidade reservada');

  const AvailabilityStatus(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Converte string para enum
  static AvailabilityStatus fromString(String value) {
    return AvailabilityStatus.values.firstWhere(
      (status) => status.displayName == value,
      orElse: () => AvailabilityStatus.available,
    );
  }

  /// Cor associada ao status
  Color get color {
    switch (this) {
      case AvailabilityStatus.available:
        return Colors.green;
      case AvailabilityStatus.sold:
        return Colors.red;
      case AvailabilityStatus.reserved:
        return Colors.orange;
    }
  }
}