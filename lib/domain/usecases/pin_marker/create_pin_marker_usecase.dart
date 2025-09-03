import '../../entities/pin_marker.dart';
import '../../repositories/pin_marker_repository.dart';
import '../usecase.dart';

class CreatePinMarkerParams {
  final String menuLocalId;
  final String title;
  final String? description;
  final double positionX;
  final double positionY;
  final PinIconType iconType;
  final String iconColor;
  final PinActionType actionType;
  final Map<String, dynamic>? actionData;
  final bool isVisible;
  
  CreatePinMarkerParams({
    required this.menuLocalId,
    required this.title,
    this.description,
    required this.positionX,
    required this.positionY,
    this.iconType = PinIconType.defaultIcon,
    this.iconColor = '#FF0000',
    this.actionType = PinActionType.info,
    this.actionData,
    this.isVisible = true,
  });
}

class CreatePinMarkerUseCase implements UseCase<PinMarker, CreatePinMarkerParams> {
  final PinMarkerRepository _repository;
  
  CreatePinMarkerUseCase(this._repository);
  
  @override
  Future<PinMarker> call(CreatePinMarkerParams params) async {
    try {
      // Validate pin marker data
      if (params.title.trim().isEmpty) {
        throw Exception('Title cannot be empty');
      }
      
      // Validate color format (basic check)
      if (!params.iconColor.startsWith('#') || params.iconColor.length != 7) {
        throw Exception('Icon color must be in hex format (#RRGGBB)');
      }
      
      // Create pin marker
      final newMarker = PinMarker(
        localId: '', // Will be set by repository
        menuLocalId: params.menuLocalId,
        title: params.title.trim(),
        description: params.description?.trim(),
        positionX: params.positionX,
        positionY: params.positionY,
        x: params.positionX,
        y: params.positionY,
        iconType: params.iconType,
        iconColor: params.iconColor,
        actionType: params.actionType,
        actionData: params.actionData,
        isVisible: params.isVisible,
        createdAt: DateTime.now(),
        lastModifiedAt: DateTime.now(),
        isModified: true,
      );
      
      return await _repository.create(newMarker);
    } catch (e) {
      throw Exception('Failed to create pin marker: ${e.toString()}');
    }
  }
}