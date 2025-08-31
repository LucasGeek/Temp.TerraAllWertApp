import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../mappers/auth_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  final StreamController<User?> _userController = StreamController<User?>.broadcast();

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      final authToken = AuthMapper.responseToToken(response);
      await _localDataSource.storeAuthToken(response);
      
      if (response.user != null) {
        final user = AuthMapper.dtoToUser(response.user!);
        await _localDataSource.storeUser(response.user!);
        _userController.add(user);
      }

      _authStateController.add(true);
      return authToken;
    } catch (e) {
      _authStateController.add(false);
      rethrow;
    }
  }

  @override
  Future<AuthToken> refreshToken(String refreshToken) async {
    try {
      final response = await _remoteDataSource.refreshToken(refreshToken);
      final authToken = AuthMapper.responseToToken(response);
      await _localDataSource.storeAuthToken(response);
      
      _authStateController.add(true);
      return authToken;
    } catch (e) {
      await clearToken();
      _authStateController.add(false);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (e) {
      // Continue even if remote logout fails
    } finally {
      await clearToken();
      _authStateController.add(false);
      _userController.add(null);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final localUser = await _localDataSource.getStoredUser();
      if (localUser != null) {
        final user = AuthMapper.dtoToUser(localUser);
        _userController.add(user);
        return user;
      }

      final remoteUser = await _remoteDataSource.getCurrentUser();
      if (remoteUser != null) {
        await _localDataSource.storeUser(remoteUser);
        final user = AuthMapper.dtoToUser(remoteUser);
        _userController.add(user);
        return user;
      }

      _userController.add(null);
      return null;
    } catch (e) {
      _userController.add(null);
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final isAuth = await _localDataSource.isAuthenticated();
    _authStateController.add(isAuth);
    return isAuth;
  }

  @override
  Future<AuthToken?> getStoredToken() async {
    final response = await _localDataSource.getStoredAuthToken();
    if (response == null) return null;
    
    return AuthMapper.responseToToken(response);
  }

  @override
  Future<void> storeToken(AuthToken token) async {
    // This would require converting back to response format
    // For now, this is handled in login/refresh methods
  }

  @override
  Future<void> clearToken() async {
    await _localDataSource.clearAuthToken();
    await _localDataSource.clearUser();
  }

  @override
  Stream<bool> watchAuthState() {
    return _authStateController.stream;
  }

  @override
  Stream<User?> watchCurrentUser() {
    return _userController.stream;
  }

  void dispose() {
    _authStateController.close();
    _userController.close();
  }
}