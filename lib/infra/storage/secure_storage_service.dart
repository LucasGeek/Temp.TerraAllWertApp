import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../infra/logging/app_logger.dart';
import '../../domain/entities/user.dart';

/// Service for secure storage of authentication data
/// Uses different storage methods based on platform capabilities
class SecureStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _isAuthenticatedKey = 'is_authenticated';
  
  SharedPreferences? _prefs;

  /// Initialize storage service
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      StorageLogger.info('Storage service initialized successfully');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to initialize storage service', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    try {
      await _ensureInitialized();
      final token = _prefs!.getString(_accessTokenKey);
      
      if (token != null) {
        StorageLogger.debug('Access token retrieved from storage');
      } else {
        StorageLogger.debug('No access token found in storage');
      }
      
      return token;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get access token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      await _ensureInitialized();
      final token = _prefs!.getString(_refreshTokenKey);
      
      if (token != null) {
        StorageLogger.debug('Refresh token retrieved from storage');
      } else {
        StorageLogger.debug('No refresh token found in storage');
      }
      
      return token;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get refresh token', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Store authentication tokens
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    try {
      await _ensureInitialized();
      
      StorageLogger.info('Storing authentication tokens');
      
      await Future.wait([
        _prefs!.setString(_accessTokenKey, accessToken),
        _prefs!.setString(_refreshTokenKey, refreshToken),
        _prefs!.setBool(_isAuthenticatedKey, true),
      ]);

      // Store expiry time if provided
      if (expiresAt != null) {
        await _prefs!.setString(_tokenExpiryKey, expiresAt.toIso8601String());
        StorageLogger.info('Token expiry time stored: ${expiresAt.toIso8601String()}');
      }

      AuthLogger.tokenStored();
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to store tokens', error: e, stackTrace: stackTrace);
      AuthLogger.tokenStorageFailure(e.toString());
      rethrow;
    }
  }

  /// Store user data
  Future<void> setUserData(User user) async {
    try {
      await _ensureInitialized();
      
      StorageLogger.info('Storing user data for userId: ${user.id}');
      
      final userData = {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'avatar': user.avatar,
        'role': {
          'id': user.role.id,
          'name': user.role.name,
          'code': user.role.code,
        },
      };

      final jsonString = jsonEncode(userData);
      await _prefs!.setString(_userDataKey, jsonString);
      
      StorageLogger.info('User data stored successfully');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to store user data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get stored user data
  Future<User?> getUserData() async {
    try {
      await _ensureInitialized();
      
      final jsonString = _prefs!.getString(_userDataKey);
      if (jsonString == null) {
        StorageLogger.debug('No user data found in storage');
        return null;
      }

      final userData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final user = User(
        id: userData['id'] as String,
        email: userData['email'] as String,
        name: userData['name'] as String,
        avatar: userData['avatar'] as String?,
        role: UserRole(
          id: userData['role']['id'] as String,
          name: userData['role']['name'] as String,
          code: userData['role']['code'] as String,
        ),
      );

      StorageLogger.debug('User data retrieved from storage for userId: ${user.id}');
      return user;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get user data', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      await _ensureInitialized();
      
      final expiryString = _prefs!.getString(_tokenExpiryKey);
      if (expiryString == null) {
        StorageLogger.debug('No token expiry time found');
        return true;
      }

      final expiryTime = DateTime.parse(expiryString);
      final isExpired = DateTime.now().isAfter(expiryTime);
      
      if (isExpired) {
        StorageLogger.warning('Token has expired at: $expiryString');
      } else {
        StorageLogger.debug('Token is still valid until: $expiryString');
      }
      
      return isExpired;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to check token expiry', error: e, stackTrace: stackTrace);
      return true; // Assume expired on error
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      await _ensureInitialized();
      
      final isAuth = _prefs!.getBool(_isAuthenticatedKey) ?? false;
      final hasToken = await getAccessToken() != null;
      final tokenValid = !await isTokenExpired();
      
      final authenticated = isAuth && hasToken && tokenValid;
      
      StorageLogger.debug('Authentication status: authenticated=$authenticated, hasToken=$hasToken, tokenValid=$tokenValid');
      
      return authenticated;
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to check authentication status', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Clear all stored authentication data
  Future<void> clearTokens() async {
    try {
      await _ensureInitialized();
      
      StorageLogger.info('Clearing all authentication data');
      
      await Future.wait([
        _prefs!.remove(_accessTokenKey),
        _prefs!.remove(_refreshTokenKey),
        _prefs!.remove(_userDataKey),
        _prefs!.remove(_tokenExpiryKey),
        _prefs!.setBool(_isAuthenticatedKey, false),
      ]);

      StorageLogger.info('All authentication data cleared successfully');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to clear tokens', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Clear specific data (for debugging)
  Future<void> clearAll() async {
    try {
      await _ensureInitialized();
      await _prefs!.clear();
      StorageLogger.warning('All stored data cleared (debug operation)');
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to clear all data', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get storage info for debugging
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      await _ensureInitialized();
      
      return {
        'hasAccessToken': await getAccessToken() != null,
        'hasRefreshToken': await getRefreshToken() != null,
        'hasUserData': _prefs!.containsKey(_userDataKey),
        'isAuthenticated': _prefs!.getBool(_isAuthenticatedKey) ?? false,
        'tokenExpiry': _prefs!.getString(_tokenExpiryKey),
        'isTokenExpired': await isTokenExpired(),
      };
    } catch (e, stackTrace) {
      StorageLogger.error('Failed to get storage info', error: e, stackTrace: stackTrace);
      return {'error': e.toString()};
    }
  }

  /// Ensure storage is initialized
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
  }

  /// Platform-specific storage capabilities
  Map<String, bool> get storageCapabilities {
    return {
      'supportsSecureStorage': !kIsWeb, // Web doesn't support flutter_secure_storage
      'supportsSharedPreferences': true,
      'isWeb': kIsWeb,
      'isMobile': Platform.isAndroid || Platform.isIOS,
      'isDesktop': Platform.isMacOS || Platform.isWindows || Platform.isLinux,
    };
  }
}

// Provider
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});