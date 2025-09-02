import '../entities/menu_types.dart';

abstract class MenuRepository {
  Future<List<Menu>> getAllMenus();
  
  Future<Menu?> getMenuById(String id);
  
  Future<List<Menu>> getMenusByType(TipoMenu tipoMenu, {TipoTela? tipoTela});
  
  Future<List<Menu>> getSubmenus(String menuPaiId);
  
  Future<Menu> createMenu({
    required String title,
    String? description,
    String? icon,
    String? route,
    bool isActive = true,
    required TipoMenu tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  });
  
  Future<Menu> updateMenu(String id, {
    String? title,
    String? description,
    String? icon,
    String? route,
    bool? isActive,
    TipoMenu? tipoMenu,
    TipoTela? tipoTela,
    String? menuPaiId,
    int? posicao,
  });
  
  Future<bool> deleteMenu(String id);
  
  Future<bool> reorderMenus(List<MenuOrder> orders);
  
  Future<MenuFloor?> getMenuFloor(String menuId);
  
  Future<MenuFloor> updateMenuFloor(String menuId, MenuFloorInput input);
  
  Future<MenuCarousel?> getMenuCarousel(String menuId);
  
  Future<MenuCarousel> updateMenuCarousel(String menuId, MenuCarouselInput input);
  
  Future<MenuPin?> getMenuPin(String menuId);
  
  Future<MenuPin> updateMenuPin(String menuId, MenuPinInput input);
  
  Stream<List<Menu>> watchMenus();
  
  Stream<Menu?> watchMenuById(String id);
}

class MenuOrder {
  final String id;
  final int posicao;
  
  MenuOrder({required this.id, required this.posicao});
}

class MenuFloorInput {
  final Map<String, dynamic>? layoutJson;
  final double? zoomDefault;
  final bool? allowZoom;
  final bool? showGrid;
  final int? gridSize;
  final String? backgroundColor;
  final int? floorCount;
  final int? defaultFloor;
  final List<String>? floorLabels;
  
  MenuFloorInput({
    this.layoutJson,
    this.zoomDefault,
    this.allowZoom,
    this.showGrid,
    this.gridSize,
    this.backgroundColor,
    this.floorCount,
    this.defaultFloor,
    this.floorLabels,
  });
}

class MenuCarouselInput {
  final List<CarouselImage>? images;
  final int? transitionTime;
  final String? transitionType;
  final bool? autoPlay;
  final bool? showIndicators;
  final bool? showArrows;
  final bool? allowSwipe;
  final bool? infiniteLoop;
  final String? aspectRatio;
  
  MenuCarouselInput({
    this.images,
    this.transitionTime,
    this.transitionType,
    this.autoPlay,
    this.showIndicators,
    this.showArrows,
    this.allowSwipe,
    this.infiniteLoop,
    this.aspectRatio,
  });
}

class MenuPinInput {
  final Map<String, dynamic>? mapConfig;
  final List<PinData>? pinData;
  final String? backgroundImageUrl;
  final Map<String, dynamic>? mapBounds;
  final double? initialZoom;
  final double? minZoom;
  final double? maxZoom;
  final bool? enableClustering;
  final int? clusterRadius;
  final String? pinIconDefault;
  final bool? showPinLabels;
  final bool? enableSearch;
  final bool? enableFilters;
  
  MenuPinInput({
    this.mapConfig,
    this.pinData,
    this.backgroundImageUrl,
    this.mapBounds,
    this.initialZoom,
    this.minZoom,
    this.maxZoom,
    this.enableClustering,
    this.clusterRadius,
    this.pinIconDefault,
    this.showPinLabels,
    this.enableSearch,
    this.enableFilters,
  });
}