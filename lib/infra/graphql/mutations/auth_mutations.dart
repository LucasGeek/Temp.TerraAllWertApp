// GraphQL mutations for authentication operations

const String loginMutation = '''
  mutation Login(\$input: LoginInput!) {
    login(input: \$input) {
      token
      refreshToken
      expiresAt
      user {
        id
        username
        email
        role
        active
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
      username
      email
      role
      active
    }
  }
''';

const String signupMutation = '''
  mutation Signup(\$email: String!, \$password: String!, \$name: String!) {
    signup(email: \$email, password: \$password, name: \$name) {
      token
      refreshToken
      expiresAt
      user {
        id
        email
        name
        avatar
        role {
          id
          name
          code
        }
      }
    }
  }
''';
