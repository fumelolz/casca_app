import 'package:casca_app/core/errors/api_exception.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

typedef ApiDecoder<T> = T Function(Object? data);

class ApiClient {
  ApiClient(this._dio, this._cookieJar);

  final Dio _dio;
  final CookieJar _cookieJar;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required ApiDecoder<T> decode,
  }) {
    return _send(() => _dio.get<Object?>(path, queryParameters: query), decode);
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, String>? headers,
    required ApiDecoder<T> decode,
  }) {
    return _send(
      () => _dio.post<Object?>(
        path,
        data: body,
        options: headers == null ? null : Options(headers: headers),
      ),
      decode,
    );
  }

  Future<T> put<T>(String path, {Object? body, required ApiDecoder<T> decode}) {
    return _send(() => _dio.put<Object?>(path, data: body), decode);
  }

  Future<void> delete(String path, {Map<String, dynamic>? query}) {
    return _send(
      () => _dio.delete<Object?>(path, queryParameters: query),
      (_) {},
    );
  }

  Future<void> postVoid(String path, {Object? body}) {
    return post<void>(path, body: body, decode: (_) {});
  }

  Future<void> clearCookies() => _cookieJar.deleteAll();

  Future<T> _send<T>(
    Future<Response<Object?>> Function() request,
    ApiDecoder<T> decode,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      return decode(data);
    } on DioException catch (error) {
      throw _toException(error);
    } on FormatException {
      throw const ApiException(type: ApiErrorType.unknown);
    } on TypeError {
      throw const ApiException(type: ApiErrorType.unknown);
    }
  }

  ApiException _toException(DioException error) {
    final status = error.response?.statusCode;
    final message = _serverMessage(error.response?.data);

    if (status == null) {
      return ApiException(type: _typeWithoutResponse(error.type));
    }
    if (status == 401) {
      return ApiException(
        type: ApiErrorType.unauthorized,
        statusCode: status,
        serverMessage: message,
      );
    }
    if (status >= 500) {
      return ApiException(
        type: ApiErrorType.server,
        statusCode: status,
        serverMessage: message,
      );
    }
    return ApiException(
      type: ApiErrorType.client,
      statusCode: status,
      serverMessage: message,
      details: _errorDetails(error.response?.data),
    );
  }

  List<ApiErrorDetail> _errorDetails(Object? body) {
    final errors = body is Map<String, dynamic> ? body['errors'] : null;
    if (errors is! List<Object?>) return const [];

    return [
      for (final item in errors)
        if (item case {'description': final String description})
          ApiErrorDetail(
            description: description,
            code: item['code'] is String ? item['code'] as String : null,
            field: item['field'] is String ? item['field'] as String : null,
          ),
    ];
  }

  ApiErrorType _typeWithoutResponse(DioExceptionType type) {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => ApiErrorType.network,
      _ => ApiErrorType.unknown,
    };
  }

  String? _serverMessage(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    final message = body['message'] ?? body['detail'] ?? body['title'];
    return message is String && message.isNotEmpty ? message : null;
  }
}
