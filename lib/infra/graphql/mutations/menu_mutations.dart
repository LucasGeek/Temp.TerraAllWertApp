// GraphQL mutations for menu/navigation operations

const String createMenuMutation = '''
  mutation CreateMenu(\$input: CreateMenuInput!) {
    createMenu(input: \$input) {
      menu {
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
          route
        }
      }
    }
  }
''';

const String updateMenuMutation = '''
  mutation UpdateMenu(\$input: UpdateMenuInput!) {
    updateMenu(input: \$input) {
      menu {
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
''';

const String deleteMenuMutation = '''
  mutation DeleteMenu(\$menuId: String!) {
    deleteMenu(menuId: \$menuId) {
      success
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