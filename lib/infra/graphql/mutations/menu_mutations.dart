// GraphQL mutations for menu/navigation operations

const String createMenuMutation = '''
  mutation CreateMenu(\$input: CreateMenuInput!) {
    createMenu(input: \$input) {
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

const String updateMenuMutation = '''
  mutation UpdateMenu(\$id: String!, \$input: UpdateMenuInput!) {
    updateMenu(id: \$id, input: \$input) {
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
      updatedAt
    }
  }
''';

const String deleteMenuMutation = '''
  mutation DeleteMenu(\$id: String!) {
    deleteMenu(id: \$id) {
      success
      message
    }
  }
''';

const String reorderMenusMutation = '''
  mutation ReorderMenus(\$input: ReorderMenusInput!) {
    reorderMenus(input: \$input) {
      success
      menus {
        id
        order
        updatedAt
      }
    }
  }
''';

const String batchCreateMenusMutation = '''
  mutation BatchCreateMenus(\$input: BatchCreateMenusInput!) {
    batchCreateMenus(input: \$input) {
      success
      menus {
        id
        label
        route
        order
        isVisible
        isEnabled
        createdAt
      }
      errors {
        field
        message
      }
    }
  }
''';