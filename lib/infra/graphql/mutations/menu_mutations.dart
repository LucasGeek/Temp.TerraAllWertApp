// Mutations GraphQL para a nova estrutura de menus

const String createMenuMutation = r'''
  mutation CreateMenu($input: MenuInput!) {
    createMenu(input: $input) {
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

const String updateMenuMutation = r'''
  mutation UpdateMenu($id: ID!, $input: MenuInput!) {
    updateMenu(id: $id, input: $input) {
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
      updatedAt
    }
  }
''';

const String deleteMenuMutation = r'''
  mutation DeleteMenu($id: ID!) {
    deleteMenu(id: $id) {
      success
      message
    }
  }
''';

const String reorderMenusMutation = r'''
  mutation ReorderMenus($menuOrders: [MenuOrderInput!]!) {
    reorderMenus(menuOrders: $menuOrders) {
      success
      message
    }
  }
''';

const String updateMenuFloorMutation = r'''
  mutation UpdateMenuFloor($menuId: ID!, $input: MenuFloorInput!) {
    updateMenuFloor(menuId: $menuId, input: $input) {
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
      updatedAt
    }
  }
''';

const String updateMenuCarouselMutation = r'''
  mutation UpdateMenuCarousel($menuId: ID!, $input: MenuCarouselInput!) {
    updateMenuCarousel(menuId: $menuId, input: $input) {
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
      updatedAt
    }
  }
''';

const String updateMenuPinMutation = r'''
  mutation UpdateMenuPin($menuId: ID!, $input: MenuPinInput!) {
    updateMenuPin(menuId: $menuId, input: $input) {
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
      updatedAt
    }
  }
''';