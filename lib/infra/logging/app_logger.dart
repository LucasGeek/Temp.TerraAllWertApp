import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  static const String _name = 'TerraAllwert';
  
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level, 
    String message, {
    String? tag, 
    Object? error, 
    StackTrace? stackTrace
  }) {
    if (!kDebugMode && level == LogLevel.debug) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final levelName = level.name.toUpperCase();
    final tagPrefix = tag != null ? '[$tag] ' : '';
    final fullMessage = '$timestamp [$levelName] $_name: $tagPrefix$message';
    
    // Use different methods based on level
    switch (level) {
      case LogLevel.debug:
        developer.log(
          fullMessage,
          name: _name,
          level: 500, // Debug level
          error: error,
          stackTrace: stackTrace,
        );
        break;
      case LogLevel.info:
        developer.log(
          fullMessage,
          name: _name,
          level: 800, // Info level
          error: error,
          stackTrace: stackTrace,
        );
        break;
      case LogLevel.warning:
        developer.log(
          fullMessage,
          name: _name,
          level: 900, // Warning level
          error: error,
          stackTrace: stackTrace,
        );
        break;
      case LogLevel.error:
        developer.log(
          fullMessage,
          name: _name,
          level: 1000, // Error level
          error: error,
          stackTrace: stackTrace,
        );
        break;
    }
    
    // Also print to console in debug mode
    if (kDebugMode) {
      if (level == LogLevel.error && error != null) {
        debugPrint('$fullMessage\nError: $error');
        if (stackTrace != null) {
          debugPrint('StackTrace: $stackTrace');
        }
      } else {
        debugPrint(fullMessage);
      }
    }
  }
}

// Specific loggers for different modules
class AuthLogger {
  static const String _tag = 'AUTH';
  
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.debug(message, tag: _tag, error: error, stackTrace: stackTrace);
  }
  
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.info(message, tag: _tag, error: error, stackTrace: stackTrace);
  }
  
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.warning(message, tag: _tag, error: error, stackTrace: stackTrace);
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.error(message, tag: _tag, error: error, stackTrace: stackTrace);
  }
  
  static void loginAttempt(String email) {
    info('Login attempt for email: ${_maskEmail(email)}');
  }
  
  static void loginSuccess(String email, String userId) {
    info('Login successful for email: ${_maskEmail(email)}, userId: $userId');
  }
  
  static void loginFailure(String email, String error) {
    warning('Login failed for email: ${_maskEmail(email)}, error: $error');
  }
  
  static void tokenReceived(String tokenType, int expiresInSeconds) {
    info('Token received: type=$tokenType, expiresIn=${expiresInSeconds}s');
  }
  
  static void tokenStored() {
    info('Authentication tokens stored successfully');
  }
  
  static void tokenStorageFailure(String errorMsg) {
    error('Failed to store authentication tokens: $errorMsg');
  }
  
  static void userDataReceived(Map<String, dynamic> userData) {
    final sanitizedData = {
      'id': userData['id'],
      'email': _maskEmail(userData['email'] ?? ''),
      'name': userData['name'],
      'role': userData['role']?['name'] ?? 'Unknown',
    };
    info('User data received: $sanitizedData');
  }
  
  static void logoutAttempt() {
    info('Logout attempt initiated');
  }
  
  static void logoutSuccess() {
    info('Logout completed successfully');
  }
  
  static void logoutFailure(String error) {
    warning('Logout failed: $error');
  }
  
  static void navigationToHome() {
    info('Navigating to home screen after successful login');
  }
  
  // Utility method to mask sensitive email data
  static String _maskEmail(String email) {
    if (email.isEmpty) return '[empty]';
    
    final parts = email.split('@');
    if (parts.length != 2) return '[invalid_email]';
    
    final localPart = parts[0];
    final domain = parts[1];
    
    if (localPart.length <= 2) {
      return '${localPart[0]}*@$domain';
    } else {
      return '${localPart.substring(0, 2)}***@$domain';
    }
  }
}

class StorageLogger {
  static const String _tag = 'STORAGE';
  
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.debug(message, tag: _tag, error: error, stackTrace: stackTrace);
  }
  
  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.info(message, tag: _tag, error: error, stackTrace: stackTrace);
  }
  
  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.warning(message, tag: _tag, error: error, stackTrace: stackTrace);
  }
  
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.error(message, tag: _tag, error: error, stackTrace: stackTrace);
  }
}