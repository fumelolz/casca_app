import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_http_adapter.dart';

ApiClient _client(FakeHandler handler, {CookieJar? jar}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(handler);
  return ApiClient(dio, jar ?? DefaultCookieJar());
}

Future<ApiException> _failure(Future<Object?> Function() action) async {
  try {
    await action();
  } on ApiException catch (error) {
    return error;
  }
  throw StateError('Se esperaba una ApiException');
}

void main() {
  test('extrae la propiedad data del envelope de la respuesta', () async {
    final client = _client(
      (_) async => jsonResponse({
        'status': 'ok',
        'data': {'name': 'Casca'},
      }, 200),
    );

    final name = await client.get<String>(
      '/demo',
      decode: (data) => (data as Map<String, dynamic>)['name'] as String,
    );

    expect(name, 'Casca');
  });

  test(
    'un 401 se convierte en ApiException no autorizada con su mensaje',
    () async {
      final client = _client(
        (_) async => jsonResponse({'message': 'Credenciales inválidas'}, 401),
      );

      final error = await _failure(
        () => client.post<void>('/demo', decode: (_) {}),
      );

      expect(error.type, ApiErrorType.unauthorized);
      expect(error.statusCode, 401);
      expect(error.message, 'Credenciales inválidas');
    },
  );

  test('un 500 se convierte en ApiException de servidor', () async {
    final client = _client((_) async => jsonResponse({}, 500));

    final error = await _failure(
      () => client.get<void>('/demo', decode: (_) {}),
    );

    expect(error.type, ApiErrorType.server);
    expect(error.message, 'El servidor no pudo procesar la solicitud.');
  });

  test('un 400 se convierte en ApiException de cliente', () async {
    final client = _client(
      (_) async => jsonResponse({'title': 'Datos inválidos'}, 400),
    );

    final error = await _failure(
      () => client.get<void>('/demo', decode: (_) {}),
    );

    expect(error.type, ApiErrorType.client);
    expect(error.message, 'Datos inválidos');
  });

  test('sin conexión se convierte en ApiException de red', () async {
    final client = _client(
      (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'sin red',
      ),
    );

    final error = await _failure(
      () => client.get<void>('/demo', decode: (_) {}),
    );

    expect(error.type, ApiErrorType.network);
  });

  test(
    'un decoder que falla se convierte en ApiException desconocida',
    () async {
      final client = _client((_) async => jsonResponse({'data': null}, 200));

      final error = await _failure(
        () => client.get<String>(
          '/demo',
          decode: (data) => (data as Map<String, dynamic>)['name'] as String,
        ),
      );

      expect(error.type, ApiErrorType.unknown);
    },
  );

  test('clearCookies vacía el jar', () async {
    final jar = DefaultCookieJar();
    final uri = Uri.parse('https://api.test');
    await jar.saveFromResponse(uri, [Cookie('accessToken', 'abc')]);
    final client = _client((_) async => jsonResponse({}, 200), jar: jar);

    await client.clearCookies();

    expect(await jar.loadForRequest(uri), isEmpty);
  });
}
