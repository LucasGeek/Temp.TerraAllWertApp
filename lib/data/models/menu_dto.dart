import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/menu.dart';

part 'menu_dto.freezed.dart';
part 'menu_dto.g.dart';

@freezed
abstract class MenuDto with _$MenuDto {
  const factory MenuDto({
    required String id,
    String? enterpriseId,
    String? parentMenuId,
    required String title,
    required String slug,
    required String screenType,
    @Default('standard') String menuType,
    @Default(0) int position,
    String? icon,
    @Default(true) bool isVisible,
    String? pathHierarchy,
    @Default(0) int depthLevel,
    @Default(true) bool isAvailableOffline,
    @Default(false) bool requiresSync,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _MenuDto;

  factory MenuDto.fromJson(Map<String, dynamic> json) => _$MenuDtoFromJson(json);
}

extension MenuDtoMapper on MenuDto {
  Menu toEntity(String localId) {
    return Menu(
      localId: localId,
      remoteId: id,
      enterpriseLocalId: enterpriseId ?? '',
      parentMenuLocalId: parentMenuId,
      title: title,
      name: title,
      description: null,
      slug: slug,
      screenType: _parseScreenType(screenType),
      menuType: _parseMenuType(menuType),
      position: position,
      icon: icon,
      iconUrl: icon,
      configuration: null,
      isVisible: isVisible,
      isActive: isVisible,
      pathHierarchy: pathHierarchy,
      depthLevel: depthLevel,
      isAvailableOffline: isAvailableOffline,
      requiresSync: requiresSync,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
  
  ScreenType _parseScreenType(String type) {
    switch (type.toLowerCase()) {
      case 'carousel':
        return ScreenType.carousel;
      case 'pin':
        return ScreenType.pin;
      case 'floorplan':
        return ScreenType.floorplan;
      default:
        return ScreenType.carousel;
    }
  }
  
  MenuType _parseMenuType(String type) {
    switch (type.toLowerCase()) {
      case 'standard':
        return MenuType.standard;
      case 'submenu':
        return MenuType.submenu;
      default:
        return MenuType.standard;
    }
  }
}

extension MenuMapper on Menu {
  MenuDto toDto() {
    return MenuDto(
      id: remoteId ?? localId,
      enterpriseId: enterpriseLocalId,
      parentMenuId: parentMenuLocalId,
      title: title,
      slug: slug,
      screenType: screenType.name,
      menuType: menuType.name,
      position: position,
      icon: icon,
      isVisible: isVisible,
      pathHierarchy: pathHierarchy,
      depthLevel: depthLevel,
      isAvailableOffline: isAvailableOffline,
      requiresSync: requiresSync,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}