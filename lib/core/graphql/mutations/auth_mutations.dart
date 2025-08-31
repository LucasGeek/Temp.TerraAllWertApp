const String loginMutation = '''
  mutation Login(\$email: String!, \$password: String!) {
    login(input: { email: \$email, password: \$password }) {
      accessToken
      refreshToken
      expiresAt
      tokenType
      user {
        id
        email
        name
        avatar
        isActive
        role {
          id
          name
          code
          permissions
        }
        createdAt
        updatedAt
      }
    }
  }
''';

const String refreshTokenMutation = '''
  mutation RefreshToken(\$refreshToken: String!) {
    refreshToken(input: { refreshToken: \$refreshToken }) {
      accessToken
      refreshToken
      expiresAt
      tokenType
    }
  }
''';

const String logoutMutation = '''
  mutation Logout {
    logout {
      success
      message
    }
  }
''';

const String getCurrentUserQuery = '''
  query GetCurrentUser {
    me {
      id
      email
      name
      avatar
      isActive
      role {
        id
        name
        code
        permissions
      }
      createdAt
      updatedAt
    }
  }
''';