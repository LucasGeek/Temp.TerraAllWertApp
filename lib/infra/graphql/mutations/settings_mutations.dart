const String updateAppSettingsMutation = '''
  mutation UpdateAppSettings(\$input: UpdateAppSettingsInput!) {
    updateAppSettings(input: \$input) {
      success
      settings {
        id
        appName
        logoUrl
        primaryColor
        secondaryColor
        updatedAt
      }
      errors {
        field
        message
      }
    }
  }
''';

const String uploadAppLogoMutation = '''
  mutation UploadAppLogo(\$input: UploadAppLogoInput!) {
    uploadAppLogo(input: \$input) {
      success
      logoUrl
      uploadUrl
      errors {
        field
        message
      }
    }
  }
''';

const String getAppSettingsQuery = '''
  query GetAppSettings {
    appSettings {
      id
      appName
      logoUrl
      primaryColor
      secondaryColor
      createdAt
      updatedAt
    }
  }
''';