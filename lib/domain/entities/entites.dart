import 'package:freezed_annotation/freezed_annotation.dart';

class IntFlexConverter implements JsonConverter<int, Object?> {
  const IntFlexConverter();
  @override
  int fromJson(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }

  @override
  Object toJson(int v) => v;
}

class BoolFlexConverter implements JsonConverter<bool, Object?> {
  const BoolFlexConverter();
  @override
  bool fromJson(Object? v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  @override
  Object toJson(bool v) => v;
}

class DateTimeIsoConverter implements JsonConverter<DateTime?, String?> {
  const DateTimeIsoConverter();
  @override
  DateTime? fromJson(String? v) => (v == null || v.isEmpty) ? null : DateTime.tryParse(v);
  @override
  String? toJson(DateTime? v) => v?.toIso8601String();
}
