/// GraphQL mutations for authentication operations

const String loginMutation = '''
  mutation Login(\$email: String!, \$password: String!) {
    login(email: \$email, password: \$password) {
      token
      refreshToken
      expiresAt
      user {
        id
        email
        name
        avatar
      }
    }
  }
''';

const String refreshTokenMutation = '''
  mutation RefreshToken(\$refreshToken: String!) {
    refreshToken(refreshToken: \$refreshToken) {
      token
      refreshToken
      expiresAt
    }
  }
''';

const String logoutMutation = '''
  mutation Logout {
    logout {
      success
    }
  }
''';

const String getCurrentUserQuery = '''
  query GetCurrentUser {
    currentUser {
      id
      email
      name
      avatar
    }
  }
''';
