import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/register_request.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

ProviderContainer _container(FakeAuthRepository repo) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<ProviderContainer> _started(FakeAuthRepository repo) async {
  final container = _container(repo);
  container.read(authControllerProvider);
  await Future<void>.delayed(Duration.zero);
  return container;
}

AuthStatus _status(ProviderContainer container) {
  return container.read(authControllerProvider).status;
}

void main() {
  test(
    'inicia en initializing y pasa a authenticated si /me responde',
    () async {
      final container = _container(FakeAuthRepository(hasSession: true));

      expect(_status(container), AuthStatus.initializing);
      await Future<void>.delayed(Duration.zero);

      expect(_status(container), AuthStatus.authenticated);
      expect(container.read(authControllerProvider).session, isNotNull);
    },
  );

  test('pasa a unauthenticated si /me falla', () async {
    final container = await _started(FakeAuthRepository());

    expect(_status(container), AuthStatus.unauthenticated);
    expect(container.read(authControllerProvider).session, isNull);
  });

  test('un error de red al restaurar no cierra la sesión', () async {
    final repo = FakeAuthRepository(
      hasSession: true,
      meError: const ApiException(type: ApiErrorType.network),
    );
    final container = await _started(repo);

    expect(_status(container), AuthStatus.connectionFailed);

    repo.meError = null;
    await container.read(authControllerProvider.notifier).restoreSession();

    expect(_status(container), AuthStatus.authenticated);
  });

  test('un 401 al restaurar deja sin sesión', () async {
    final container = await _started(
      FakeAuthRepository(hasSession: true, meError: unauthorized),
    );

    expect(_status(container), AuthStatus.unauthenticated);
  });

  test('signIn autentica con la sesión del login', () async {
    final container = await _started(FakeAuthRepository());

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@a.com', password: 'x');

    expect(_status(container), AuthStatus.authenticated);
    expect(container.read(authControllerProvider).session, isNotNull);
  });

  test('signIn propaga el error y sigue sin autenticar', () async {
    final container = await _started(
      FakeAuthRepository(loginError: unauthorized),
    );

    await expectLater(
      container
          .read(authControllerProvider.notifier)
          .signIn(email: 'a@a.com', password: 'x'),
      throwsA(isA<ApiException>()),
    );

    expect(_status(container), AuthStatus.unauthenticated);
  });

  test('register autentica con la sesión devuelta', () async {
    final repo = FakeAuthRepository();
    final container = await _started(repo);

    await container
        .read(authControllerProvider.notifier)
        .register(
          const RegisterRequest(
            name: 'María',
            email: 'maria@casca.com',
            password: 'Abcdef1!',
            phone: '5551234567',
            tenantName: 'Tienda',
            businessType: BusinessType.otro,
          ),
        );

    expect(_status(container), AuthStatus.authenticated);
    expect(repo.registrations, hasLength(1));
  });

  test('signOut llama al repository y desautentica', () async {
    final repo = FakeAuthRepository(hasSession: true);
    final container = await _started(repo);

    await container.read(authControllerProvider.notifier).signOut();

    expect(repo.loggedOut, isTrue);
    expect(_status(container), AuthStatus.unauthenticated);
  });

  test('la señal de sesión expirada desautentica', () async {
    final container = await _started(FakeAuthRepository(hasSession: true));
    expect(_status(container), AuthStatus.authenticated);

    container.read(sessionExpiredProvider.notifier).notifyExpired();

    expect(_status(container), AuthStatus.unauthenticated);
  });
}
