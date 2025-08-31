import 'package:freezed_annotation/freezed_annotation.dart';
import 'pavimento.dart';

part 'tower.freezed.dart';
part 'tower.g.dart';

@freezed
class Tower with _$Tower {
  const factory Tower({
    required String id,
    required String name,
    required String description,
    String? address,
    String? imageUrl,
    required List<Pavimento> pavimentos,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isSynced,
  }) = _Tower;

  factory Tower.fromJson(Map<String, dynamic> json) => _$TowerFromJson(json);
}