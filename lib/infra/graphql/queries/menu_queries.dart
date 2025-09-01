// GraphQL queries for menu/navigation operations

const String getMenusQuery = '''
  query GetMenus(\$userId: String) {
    getMenus(userId: \$userId) {
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