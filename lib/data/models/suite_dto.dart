import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/suite.dart';

part 'suite_dto.freezed.dart';
part 'suite_dto.g.dart';

@freezed
abstract class SuiteDto with _$SuiteDto {
  const factory SuiteDto({
    required String id,
    required String floorId,
    required String unitNumber,
    required String title,
    String? description,
    double? positionX,
    double? positionY,
    required double areaSqm,
    @Default(0) int bedrooms,
    @Default(0) int suitesCount,
    @Default(0) int bathrooms,
    @Default(0) int parkingSpaces,
    String? sunPosition,
    @Default('available') String status,
    String? floorPlanFileId,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _SuiteDto;

  factory SuiteDto.fromJson(Map<String, dynamic> json) => _$SuiteDtoFromJson(json);
}

extension SuiteDtoMapper on SuiteDto {
  Suite toEntity(String localId) {
    return Suite(
      localId: localId,
      remoteId: id,
      floorLocalId: floorId,
      unitNumber: unitNumber,
      title: title,
      description: description,
      positionX: positionX,
      positionY: positionY,
      areaSqm: areaSqm,
      bedrooms: bedrooms,
      suitesCount: suitesCount,
      bathrooms: bathrooms,
      parkingSpaces: parkingSpaces,
      sunPosition: sunPosition,
      status: _parseStatus(status),
      floorPlanFileLocalId: floorPlanFileId,
      price: price,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  SuiteStatus _parseStatus(String status) {
    switch (status) {
      case 'available':
        return SuiteStatus.available;
      case 'reserved':
        return SuiteStatus.reserved;
      case 'sold':
        return SuiteStatus.sold;
      case 'blocked':
        return SuiteStatus.blocked;
      default:
        return SuiteStatus.available;
    }
  }
}

extension SuiteMapper on Suite {
  SuiteDto toDto() {
    return SuiteDto(
      id: remoteId ?? localId,
      floorId: floorLocalId,
      unitNumber: unitNumber,
      title: title,
      description: description,
      positionX: positionX,
      positionY: positionY,
      areaSqm: areaSqm,
      bedrooms: bedrooms,
      suitesCount: suitesCount,
      bathrooms: bathrooms,
      parkingSpaces: parkingSpaces,
      sunPosition: sunPosition,
      status: status.name,
      floorPlanFileId: floorPlanFileLocalId,
      price: price,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}