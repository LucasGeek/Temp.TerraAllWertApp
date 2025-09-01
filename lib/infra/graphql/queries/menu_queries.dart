// GraphQL queries for menu/navigation operations

const String getMenusQuery = '''
  query GetMenus(\$routeId: String!) {
    getMenus(routeId: \$routeId) {
      menus {
        id
        title
        type
        route
        icon
        order
        isActive
        permissions
        children {
          id
          title
          type
          route
          icon
          order
          isActive
          permissions
        }
      }
    }
  }
''';

const String getMenuByIdQuery = '''
  query GetMenuById(\$id: String!) {
    menu(id: \$id) {
      id
      label
      route
      iconCodePoint
      iconFontFamily
      selectedIconCodePoint
      selectedIconFontFamily
      order
      isVisible
      isEnabled
      description
      parentId
      menuType
      permissions
      createdAt
      updatedAt
    }
  }
''';

const String getMenusByRouteQuery = '''
  query GetMenusByRoute(\$route: String!) {
    menusByRoute(route: \$route) {
      id
      label
      route
      iconCodePoint
      iconFontFamily
      selectedIconCodePoint
      selectedIconFontFamily
      order
      isVisible
      isEnabled
      description
      parentId
      menuType
      permissions
      createdAt
      updatedAt
    }
  }
''';