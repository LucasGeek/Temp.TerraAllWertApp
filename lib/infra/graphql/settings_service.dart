import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql/client.dart';
import 'dart:typed_data';

import '../logging/app_logger.dart';
import 'graphql_client.dart';
import 'mutations/settings_mutations.dart';

class SettingsGraphQLService {
  final GraphQLClient _client;

  SettingsGraphQLService(this._client);

  /// Busca configurações do aplicativo
  Future<Map<String, dynamic>?> getAppSettings() async {
    try {
      AppLogger.info('Fetching app settings via GraphQL', tag: 'SettingsGraphQL');

      final result = await _client.query(
        QueryOptions(
          document: gql(getAppSettingsQuery),
          errorPolicy: ErrorPolicy.all,
          cacheRereadPolicy: CacheRereadPolicy.ignoreAll,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL query failed: ${result.exception}', tag: 'SettingsGraphQL');
        return null;
      }

      final data = result.data?['appSettings'];
      if (data != null) {
        AppLogger.info('App settings fetched successfully via GraphQL', tag: 'SettingsGraphQL');
        return data;
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to fetch app settings via GraphQL: $e', tag: 'SettingsGraphQL');
      return null;
    }
  }

  /// Atualiza configurações do aplicativo
  Future<AppSettingsUpdateResult> updateAppSettings({
    String? appName,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
  }) async {
    try {
      AppLogger.info('Updating app settings via GraphQL', tag: 'SettingsGraphQL');

      final variables = <String, dynamic>{
        'input': <String, dynamic>{}
      };

      if (appName != null) {
        variables['input']['appName'] = appName;
      }
      if (logoUrl != null) {
        variables['input']['logoUrl'] = logoUrl;
      }
      if (primaryColor != null) {
        variables['input']['primaryColor'] = primaryColor;
      }
      if (secondaryColor != null) {
        variables['input']['secondaryColor'] = secondaryColor;
      }

      final result = await _client.mutate(
        MutationOptions(
          document: gql(updateAppSettingsMutation),
          variables: variables,
          errorPolicy: ErrorPolicy.all,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL update failed: ${result.exception}', tag: 'SettingsGraphQL');
        return AppSettingsUpdateResult(
          success: false,
          error: result.exception.toString(),
        );
      }

      final settingsResponse = result.data?['updateAppSettings'];
      final success = settingsResponse?['success'] ?? false;
      final errors = settingsResponse?['errors'] as List<dynamic>?;

      if (success) {
        AppLogger.info('App settings updated successfully via GraphQL', tag: 'SettingsGraphQL');
        return AppSettingsUpdateResult(
          success: true,
          settings: settingsResponse?['settings'],
        );
      } else {
        final errorMessage = errors?.isNotEmpty == true 
            ? errors!.first['message'] 
            : 'Unknown error';
        return AppSettingsUpdateResult(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to update app settings via GraphQL: $e', tag: 'SettingsGraphQL');
      return AppSettingsUpdateResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Faz upload da logo do aplicativo
  Future<LogoUploadResult> uploadAppLogo({
    required Uint8List imageBytes,
    required String fileName,
    String contentType = 'image/png',
  }) async {
    try {
      AppLogger.info('Uploading app logo via GraphQL', tag: 'SettingsGraphQL');

      // Primeiro, solicitar URL de upload assinada
      final result = await _client.mutate(
        MutationOptions(
          document: gql(uploadAppLogoMutation),
          variables: {
            'input': {
              'fileName': fileName,
              'contentType': contentType,
              'fileSize': imageBytes.length,
            }
          },
          errorPolicy: ErrorPolicy.all,
        ),
      );

      if (result.hasException) {
        AppLogger.error('GraphQL logo upload request failed: ${result.exception}', tag: 'SettingsGraphQL');
        return LogoUploadResult(
          success: false,
          error: result.exception.toString(),
        );
      }

      final uploadResponse = result.data?['uploadAppLogo'];
      final success = uploadResponse?['success'] ?? false;
      final errors = uploadResponse?['errors'] as List<dynamic>?;

      if (success) {
        final uploadUrl = uploadResponse?['uploadUrl'] as String?;
        final logoUrl = uploadResponse?['logoUrl'] as String?;

        AppLogger.info('App logo upload URL obtained successfully', tag: 'SettingsGraphQL');
        return LogoUploadResult(
          success: true,
          uploadUrl: uploadUrl,
          logoUrl: logoUrl,
        );
      } else {
        final errorMessage = errors?.isNotEmpty == true 
            ? errors!.first['message'] 
            : 'Unknown error';
        return LogoUploadResult(
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to upload app logo via GraphQL: $e', tag: 'SettingsGraphQL');
      return LogoUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// Resultado da atualização de configurações
class AppSettingsUpdateResult {
  final bool success;
  final Map<String, dynamic>? settings;
  final String? error;

  AppSettingsUpdateResult({
    required this.success,
    this.settings,
    this.error,
  });
}

/// Resultado do upload de logo
class LogoUploadResult {
  final bool success;
  final String? uploadUrl;
  final String? logoUrl;
  final String? error;

  LogoUploadResult({
    required this.success,
    this.uploadUrl,
    this.logoUrl,
    this.error,
  });
}

/// Provider para o serviço GraphQL de configurações
final settingsGraphQLServiceProvider = Provider<SettingsGraphQLService>((ref) {
  final clientService = ref.watch(graphQLClientProvider);  
  return SettingsGraphQLService(clientService.client);
});