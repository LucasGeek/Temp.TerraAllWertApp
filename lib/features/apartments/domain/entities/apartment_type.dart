import 'package:freezed_annotation/freezed_annotation.dart';

part 'apartment_type.freezed.dart';
part 'apartment_type.g.dart';

@freezed
class ApartmentType with _$ApartmentType {
  const factory ApartmentType({
    required String id,
    required String name,
    required String code,
    String? description,
    @Default(0) double minArea,
    @Default(0) double maxArea,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ApartmentType;

  factory ApartmentType.fromJson(Map<String, dynamic> json) => _$ApartmentTypeFromJson(json);
}