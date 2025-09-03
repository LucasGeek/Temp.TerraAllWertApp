import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

import '../config/env_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class RestClient {
  late final Dio _dio;
  late final CacheOptions _cacheOptions;

  RestClient({required EnvConfig config, String? accessToken}) {
    _cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.request,
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
    );

    _dio = Dio(
      BaseOptions(
        baseUrl: config.restApiEndpoint,
        connectTimeout: Duration(milliseconds: config.timeout),
        receiveTimeout: Duration(milliseconds: config.timeout),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    // Add interceptors
    _dio.interceptors.addAll([
      AuthInterceptor(accessToken: accessToken),
      RetryInterceptor(dio: _dio),
      DioCacheInterceptor(options: _cacheOptions),
      if (config.enableLogging) LogInterceptor(requestBody: true, responseBody: true, error: true),
    ]);
  }

  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // Update access token
  void updateAccessToken(String? token) {
    final authInterceptor =
        _dio.interceptors.firstWhere((i) => i is AuthInterceptor) as AuthInterceptor;
    authInterceptor.updateToken(token);
  }

  // Clear cache
  Future<void> clearCache() async {
    await _cacheOptions.store?.clean();
  }
}
