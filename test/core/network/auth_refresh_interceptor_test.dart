import 'package:casca_app/core/network/auth_refresh_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_http_adapter.dart';

const _protectedPath = '/api/v1/products';
const _loginPath = '/api/v1/auth/login';

class _Harness {
  _Harness({required this.refreshStatus, this.alwaysUnauthorized = false}) {
    adapter = FakeHttpAdapter(_handle);
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthRefreshInterceptor(dio: dio, onSessionExpired: () => expired++),
    );
  }

  final int refreshStatus;
  final bool alwaysUnauthorized;

  late final FakeHttpAdapter adapter;
  late final Dio dio;
  var expired = 0;
  var _refreshed = false;

  Future<ResponseBody> _handle(RequestOptions options) async {
    if (options.path == AuthRefreshInterceptor.refreshPath) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (refreshStatus == 200) _refreshed = true;
      return jsonResponse({'data': null}, refreshStatus);
    }
    if (options.path == _loginPath) return jsonResponse({}, 401);
    if (alwaysUnauthorized || !_refreshed) return jsonResponse({}, 401);
    return jsonResponse({'data': 'ok'}, 200);
  }

  int refreshCalls() =>
      adapter.count('POST', AuthRefreshInterceptor.refreshPath);
}

void main() {
  test('ante un 401 refresca la sesión y reintenta la petición', () async {
    final harness = _Harness(refreshStatus: 200);

    final response = await harness.dio.get<Object?>(_protectedPath);

    expect(response.statusCode, 200);
    expect(harness.refreshCalls(), 1);
    expect(harness.adapter.count('GET', _protectedPath), 2);
    expect(harness.expired, 0);
  });

  test('varias peticiones con 401 comparten un solo refresh', () async {
    final harness = _Harness(refreshStatus: 200);

    final responses = await Future.wait([
      harness.dio.get<Object?>(_protectedPath),
      harness.dio.get<Object?>(_protectedPath),
      harness.dio.get<Object?>(_protectedPath),
    ]);

    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(harness.refreshCalls(), 1);
  });

  test('si el refresh da 401 expira la sesión y propaga el error', () async {
    final harness = _Harness(refreshStatus: 401);

    await expectLater(
      harness.dio.get<Object?>(_protectedPath),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );

    expect(harness.expired, 1);
    expect(harness.adapter.count('GET', _protectedPath), 1);
  });

  test('no intenta refrescar en las rutas de autenticación', () async {
    final harness = _Harness(refreshStatus: 200);

    await expectLater(
      harness.dio.post<Object?>(_loginPath),
      throwsA(isA<DioException>()),
    );

    expect(harness.refreshCalls(), 0);
    expect(harness.expired, 0);
  });

  test('si el reintento vuelve a dar 401 no entra en bucle', () async {
    final harness = _Harness(refreshStatus: 200, alwaysUnauthorized: true);

    await expectLater(
      harness.dio.get<Object?>(_protectedPath),
      throwsA(isA<DioException>()),
    );

    expect(harness.refreshCalls(), 1);
    expect(harness.adapter.count('GET', _protectedPath), 2);
  });
}
