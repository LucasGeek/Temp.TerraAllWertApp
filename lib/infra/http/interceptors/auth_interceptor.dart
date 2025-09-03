import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  String? _accessToken;

  AuthInterceptor({String? accessToken}) : _accessToken = accessToken;

  void updateToken(String? token) {
    _accessToken = token;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid
      // TODO: Implement token refresh logic
    }
    handler.next(err);
  }
}