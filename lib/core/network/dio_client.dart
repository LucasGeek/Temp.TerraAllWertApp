import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:talker/talker.dart';

import '../errors/exceptions.dart';
import 'env_config.dart';

class DioClient {
  late final Dio _dio;
  final Talker _talker;

  DioClient(this._talker) {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: EnvConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: EnvConfig.apiTimeout),
        sendTimeout: Duration(milliseconds: EnvConfig.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    if (EnvConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => _talker.log(obj.toString()),
        ),
      );
    }

    final cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.request,
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      cipher: null,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );

    _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _handleDioError(error);
          handler.next(error);
        },
      ),
    );
  }

  void _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        throw ServerException(
          message: error.response?.data['message'] ?? 'Server error occurred',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        throw NetworkException(
          message: 'No internet connection. Please check your network.',
        );
      case DioExceptionType.cancel:
        throw NetworkException(message: 'Request was cancelled');
      case DioExceptionType.unknown:
        throw NetworkException(
          message: 'An unexpected error occurred: ${error.message}',
        );
      case DioExceptionType.badCertificate:
        throw NetworkException(
          message: 'Certificate error. Please contact support.',
        );
    }
  }

  Dio get dio => _dio;
}