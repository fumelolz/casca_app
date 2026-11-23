import 'dart:async';

import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/features/auth/presentation/providers/login_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_auth_repository.dart';

ProviderContainer _container(FakeAuthRepository repo) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('éxito: termina sin error y autentica', () async {
    final container = _container(FakeAuthRepository());
    final sub = container.listen(loginControllerProvider, (_, _) {});

    await container
        .read(loginControllerProvider.notifier)
        .submit(email: 'a@a.com', password: 'x');

    expect(sub.read().hasError, isFalse);
    expect(sub.read().isLoading, isFalse);
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
  });

  test('fallo: deja el error en el estado', () async {
    final container = _container(FakeAuthRepository(loginError: unauthorized));
    final sub = container.listen(loginControllerProvider, (_, _) {});

    await container
        .read(loginControllerProvider.notifier)
        .submit(email: 'a@a.com', password: 'x');

    expect(sub.read().hasError, isTrue);
    expect(sub.read().error, isA<ApiException>());
  });

  test('mientras carga ignora un segundo envío', () async {
    final gate = Completer<void>();
    final container = _container(FakeAuthRepository(gate: gate));
    final sub = container.listen(loginControllerProvider, (_, _) {});
    final controller = container.read(loginControllerProvider.notifier);

    final first = controller.submit(email: 'a@a.com', password: 'x');
    expect(sub.read().isLoading, isTrue);

    await controller.submit(email: 'otro@a.com', password: 'y');
    gate.complete();
    await first;

    expect(sub.read().isLoading, isFalse);
  });

  test('si la pantalla se destruye durante la petición no lanza', () async {
    final gate = Completer<void>();
    final container = _container(FakeAuthRepository(gate: gate));
    final sub = container.listen(loginControllerProvider, (_, _) {});

    final pending = container
        .read(loginControllerProvider.notifier)
        .submit(email: 'a@a.com', password: 'x');
    sub.close();
    await Future<void>.delayed(Duration.zero);
    gate.complete();

    await pending;
  });
}
