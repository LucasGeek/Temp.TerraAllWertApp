import '../../entities/suite.dart';
import '../../repositories/tower_repository.dart';
import '../usecase.dart';

class CreateSuiteParams {
  final String floorLocalId;
  final String unitNumber;
  final String title;
  final String? description;
  final double? positionX;
  final double? positionY;
  final double areaSqm;
  final int bedrooms;
  final int suitesCount;
  final int bathrooms;
  final int parkingSpaces;
  final String? sunPosition;
  final SuiteStatus status;
  final String? floorPlanFileLocalId;
  final double? price;
  final String? localNotes;
  
  CreateSuiteParams({
    required this.floorLocalId,
    required this.unitNumber,
    required this.title,
    this.description,
    this.positionX,
    this.positionY,
    required this.areaSqm,
    this.bedrooms = 0,
    this.suitesCount = 0,
    this.bathrooms = 0,
    this.parkingSpaces = 0,
    this.sunPosition,
    this.status = SuiteStatus.available,
    this.floorPlanFileLocalId,
    this.price,
    this.localNotes,
  });
}

class CreateSuiteUseCase implements UseCase<Suite, CreateSuiteParams> {
  final TowerRepository _towerRepository;
  
  CreateSuiteUseCase(this._towerRepository);
  
  @override
  Future<Suite> call(CreateSuiteParams params) async {
    try {
      // Validate suite data
      if (params.unitNumber.trim().isEmpty) {
        throw Exception('Unit number cannot be empty');
      }
      
      if (params.title.trim().isEmpty) {
        throw Exception('Title cannot be empty');
      }
      
      if (params.bedrooms < 0) {
        throw Exception('Bedrooms must be non-negative');
      }
      
      if (params.bathrooms < 0) {
        throw Exception('Bathrooms must be non-negative');
      }
      
      if (params.areaSqm < 0) {
        throw Exception('Area must be non-negative');
      }
      
      if (params.price != null && params.price! < 0) {
        throw Exception('Price must be non-negative');
      }
      
      // Create new suite
      final newSuite = Suite(
        localId: '', // Will be set by repository
        floorLocalId: params.floorLocalId,
        unitNumber: params.unitNumber.trim(),
        title: params.title.trim(),
        description: params.description?.trim(),
        positionX: params.positionX,
        positionY: params.positionY,
        areaSqm: params.areaSqm,
        bedrooms: params.bedrooms,
        suitesCount: params.suitesCount,
        bathrooms: params.bathrooms,
        parkingSpaces: params.parkingSpaces,
        sunPosition: params.sunPosition,
        status: params.status,
        floorPlanFileLocalId: params.floorPlanFileLocalId,
        price: params.price,
        localNotes: params.localNotes,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      return await _towerRepository.createSuite(newSuite);
    } catch (e) {
      throw Exception('Failed to create suite: ${e.toString()}');
    }
  }
}