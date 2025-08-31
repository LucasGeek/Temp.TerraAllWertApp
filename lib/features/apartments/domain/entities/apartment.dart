import 'package:freezed_annotation/freezed_annotation.dart';
import 'apartment_type.dart';

part 'apartment.freezed.dart';
part 'apartment.g.dart';

@freezed
abstract class Apartment with _$Apartment {
  const factory Apartment({
    required String id,
    required String pavimentoId,
    required String towerId,
    required String number,
    required ApartmentType type,
    required double area,
    required int bedrooms,
    required int bathrooms,
    double? price,
    String? description,
    List<String>? imageUrls,
    Map<String, dynamic>? coordinates,
    @Default(false) bool isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isSynced,
  }) = _Apartment;

  factory Apartment.fromJson(Map<String, dynamic> json) => _$ApartmentFromJson(json);
}