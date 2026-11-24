import 'package:casca_app/core/auth/auth_endpoints.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/register_request.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../network/fake_http_adapter.dart';

const _storeJson = {
  'id': 's1',
  'name': 'Matriz',
  'taxesEnabled': true,
  'isDefault': true,
  'tenantId': 't1',
  'tenantName': 'Casca Demo',
  'businessType': null,
};

final _sessionJson = {
  'account': {'id': 'a1', 'email': 'dany@casca.com', 'name': 'Dany'},
  'roles': [
    {'id': 'r1', 'name': 'Admin'},
  ],
  'permissions': ['products.read'],
  'store': _storeJson,
  'stores': [_storeJson],
  'tenantName': 'Casca Demo',
};

AuthRepository _repository(FakeHandler handler, {CookieJar? jar}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(handler);
  return AuthRepository(ApiClient(dio, jar ?? DefaultCookieJar()));
}

void main() {
  test('login envía las credenciales y devuelve la sesión', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': _sessionJson}, 200);
    });

    final session = await repository.login(
      email: 'dany@casca.com',
      password: 'secreto',
    );

    expect(sent?.path, AuthEndpoints.login);
    expect(sent?.data, {'email': 'dany@casca.com', 'password': 'secreto'});
    expect(session.account.name, 'Dany');
    expect(session.activeStore.id, 's1');
  });

  test(
    'login con credenciales inválidas lanza ApiException no autorizada',
    () async {
      final repository = _repository(
        (_) async => jsonResponse({'message': 'Credenciales inválidas'}, 401),
      );

      await expectLater(
        repository.login(email: 'a@a.com', password: 'mal'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isUnauthorized,
            'unauthorized',
            true,
          ),
        ),
      );
    },
  );

  test('me consulta la sesión actual', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': _sessionJson}, 200);
    });

    final session = await repository.me();

    expect(sent?.method, 'GET');
    expect(sent?.path, AuthEndpoints.me);
    expect(session.permissions, ['products.read']);
  });

  test('logout vacía las cookies aunque el servidor falle', () async {
    final jar = DefaultCookieJar();
    final uri = Uri.parse('https://api.test');
    await jar.saveFromResponse(uri, [Cookie('refreshToken', 'abc')]);
    final repository = _repository(
      (_) async => jsonResponse({}, 500),
      jar: jar,
    );

    await expectLater(repository.logout(), throwsA(isA<ApiException>()));

    expect(await jar.loadForRequest(uri), isEmpty);
  });

  test('registerAdmin envía el registro y devuelve la sesión', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': _sessionJson}, 200);
    });

    final session = await repository.registerAdmin(
      const RegisterRequest(
        name: 'María López',
        email: 'maria@casca.com',
        password: 'Abcdef1!',
        phone: '5551234567',
        tenantName: 'Joyería El Sol',
        businessType: BusinessType.joyeria,
      ),
    );

    expect(sent?.path, AuthEndpoints.registerAdmin);
    expect(sent?.data, {
      'name': 'María López',
      'email': 'maria@casca.com',
      'password': 'Abcdef1!',
      'phone': '5551234567',
      'tenantName': 'Joyería El Sol',
      'businessType': 'joyeria',
    });
    expect(session.account.name, 'Dany');
  });

  test('registerAdmin con correo repetido lanza ApiException 409', () async {
    final repository = _repository(
      (_) async => jsonResponse({'message': 'Ya existe'}, 409),
    );

    await expectLater(
      repository.registerAdmin(
        const RegisterRequest(
          name: 'A',
          email: 'a@a.com',
          password: 'Abcdef1!',
          phone: '5551234567',
          tenantName: 'T',
          businessType: BusinessType.otro,
        ),
      ),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );
  });

  test('forgotPassword envía solo el correo y no devuelve datos', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': null}, 200);
    });

    await repository.forgotPassword(email: 'a@b.com');

    expect(sent?.path, AuthEndpoints.forgotPassword);
    expect(sent?.data, {'email': 'a@b.com'});
  });

  test('verifyResetCode devuelve el token de sesión', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({
        'data': {'sessionToken': 'abc'},
      }, 200);
    });

    final token = await repository.verifyResetCode(
      email: 'a@b.com',
      code: '123456',
    );

    expect(sent?.path, AuthEndpoints.verifyResetCode);
    expect(sent?.data, {'email': 'a@b.com', 'code': '123456'});
    expect(token, 'abc');
  });

  test('changePassword envía el token y la contraseña nueva', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': null}, 200);
    });

    await repository.changePassword(
      sessionToken: 'abc',
      newPassword: 'Abcdef1!',
      confirmPassword: 'Abcdef1!',
    );

    expect(sent?.path, AuthEndpoints.changePassword);
    expect(sent?.data, {
      'sessionToken': 'abc',
      'newPassword': 'Abcdef1!',
      'confirmPassword': 'Abcdef1!',
    });
  });
}
