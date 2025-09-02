// Queries GraphQL para a nova estrutura de menus

const String getAllMenusQuery = r'''
  query GetAllMenus {
    menus {
      id
      title
      description
      icon
      route
      isActive
      tipoMenu
      tipoTela
      menuPaiId
      posicao
      createdAt
      updatedAt
    }
  }
''';

const String getMenuByIdQuery = r'''
  query GetMenuById($id: ID!) {
    menu(id: $id) {
      id
      title
      description
      icon
      route
      isActive
      tipoMenu
      tipoTela
      menuPaiId
      posicao
      createdAt
      updatedAt
    }
  }
''';

const String getMenuHierarchyQuery = r'''
  query GetMenuHierarchy {
    menuHierarchy {
      id
      title
      tipoMenu
      tipoTela
      menuPaiId
      menuPaiTitle
      posicao
      icon
      route
      isActive
      submenuCount
    }
  }
''';

const String getMenusByTypeQuery = r'''
  query GetMenusByType($tipoMenu: String!, $tipoTela: String) {
    menusByType(tipoMenu: $tipoMenu, tipoTela: $tipoTela) {
      id
      title
      description
      icon
      route
      isActive
      tipoMenu
      tipoTela
      menuPaiId
      posicao
    }
  }
''';

const String getSubmenusQuery = r'''
  query GetSubmenus($menuPaiId: ID!) {
    submenus(menuPaiId: $menuPaiId) {
      id
      title
      description
      icon
      route
      isActive
      tipoMenu
      tipoTela
      posicao
    }
  }
''';

const String getMenuFloorQuery = r'''
  query GetMenuFloor($menuId: ID!) {
    menuFloor(menuId: $menuId) {
      id
      menuId
      layoutJson
      zoomDefault
      allowZoom
      showGrid
      gridSize
      backgroundColor
      floorCount
      defaultFloor
      floorLabels
      createdAt
      updatedAt
    }
  }
''';

const String getMenuCarouselQuery = r'''
  query GetMenuCarousel($menuId: ID!) {
    menuCarousel(menuId: $menuId) {
      id
      menuId
      images
      transitionTime
      transitionType
      autoPlay
      showIndicators
      showArrows
      allowSwipe
      infiniteLoop
      aspectRatio
      createdAt
      updatedAt
    }
  }
''';

const String getMenuPinQuery = r'''
  query GetMenuPin($menuId: ID!) {
    menuPin(menuId: $menuId) {
      id
      menuId
      mapConfig
      pinData
      backgroundImageUrl
      mapBounds
      initialZoom
      minZoom
      maxZoom
      enableClustering
      clusterRadius
      pinIconDefault
      showPinLabels
      enableSearch
      enableFilters
      createdAt
      updatedAt
    }
  }
''';