import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../apartments/domain/entities/apartment.dart';

part 'pavimento.freezed.dart';
part 'pavimento.g.dart';

@freezed
abstract class Pavimento with _$Pavimento {
  const factory Pavimento({
    required String id,
    required String towerId,
    required String name,
    required int floor,
    String? floorPlanImageUrl,
    String? description,
    required List<Apartment> apartments,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isSynced,
  }) = _Pavimento;

  factory Pavimento.fromJson(Map<String, dynamic> json) => _$PavimentoFromJson(json);
}