import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/enterprise.dart';

part 'enterprise_dto.freezed.dart';
part 'enterprise_dto.g.dart';

@freezed
abstract class EnterpriseDto with _$EnterpriseDto {
  const factory EnterpriseDto({
    required String id,
    required String title,
    String? description,
    String? logoFileId,
    required String slug,
    String? address,
    double? latitude,
    double? longitude,
    @Default('active') String status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _EnterpriseDto;

  factory EnterpriseDto.fromJson(Map<String, dynamic> json) => 
      _$EnterpriseDtoFromJson(json);
}

extension EnterpriseDtoMapper on EnterpriseDto {
  Enterprise toEntity(String localId) {
    return Enterprise(
      localId: localId,
      remoteId: id,
      title: title,
      description: description,
      logoFileLocalId: logoFileId,
      slug: slug,
      fullAddress: address,
      latitude: latitude,
      longitude: longitude,
      status: status,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
    );
  }
}

extension EnterpriseMapper on Enterprise {
  EnterpriseDto toDto() {
    return EnterpriseDto(
      id: remoteId ?? localId,
      title: title,
      description: description,
      logoFileId: logoFileLocalId,
      slug: slug,
      address: fullAddress,
      latitude: latitude,
      longitude: longitude,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}