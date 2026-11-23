import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor({required this.dio, required this.onSessionExpired});

  static const String refreshPath = '/api/v1/auth/refreshtoken';
  static const String _retriedKey = 'casca.auth.retried';
  static const List<String> _authPaths = [
    '/api/v1/auth/login',
    '/api/v1/auth/logout',
    refreshPath,
  ];

  final Dio dio;
  final VoidCallback onSessionExpired;

  Future<void>? _refreshing;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;

    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    try {
      await (_refreshing ??= _refresh());
    } on DioException catch (refreshError) {
      if (refreshError.response?.statusCode == 401) onSessionExpired();
      handler.next(err);
      return;
    }

    request.extra[_retriedKey] = true;
    try {
      handler.resolve(await dio.fetch<Object?>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _shouldRefresh(DioException err) {
    final request = err.requestOptions;
    return err.response?.statusCode == 401 &&
        request.extra[_retriedKey] != true &&
        !_authPaths.any(request.path.contains);
  }

  Future<void> _refresh() {
    return dio
        .post<Object?>(refreshPath)
        .then<void>((_) {})
        .whenComplete(() => _refreshing = null);
  }
}
