import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/features/auth/presentation/providers/forgot_password_controller.dart';
import 'package:casca_app/features/auth/presentation/providers/set_password_controller.dart';
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
  group('ForgotPasswordController', () {
    test('empieza sin enviar', () {
      final container = _container(FakeAuthRepository());
      container.listen(forgotPasswordControllerProvider, (_, _) {});

      expect(container.read(forgotPasswordControllerProvider).value, isFalse);
    });

    test('envía el correo normalizado y marca enviado', () async {
      final repo = FakeAuthRepository();
      final container = _container(repo);
      container.listen(forgotPasswordControllerProvider, (_, _) {});

      await container
          .read(forgotPasswordControllerProvider.notifier)
          .submit('  A@B.com ');

      expect(repo.requestedEmails, ['a@b.com']);
      expect(container.read(forgotPasswordControllerProvider).value, isTrue);
    });
  });

  group('SetPasswordController', () {
    Future<AsyncValue<bool>> submit(
      FakeAuthRepository repo, {
      String code = FakeAuthRepository.validCode,
    }) async {
      final container = _container(repo);
      container.listen(setPasswordControllerProvider, (_, _) {});

      await container
          .read(setPasswordControllerProvider.notifier)
          .submit(
            email: ' a@b.com ',
            code: ' $code ',
            newPassword: 'Abcdef1!',
            confirmPassword: 'Abcdef1!',
          );

      return container.read(setPasswordControllerProvider);
    }

    test('canjea el código y cambia la contraseña con el token', () async {
      final repo = FakeAuthRepository();

      final state = await submit(repo);

      expect(state.value, isTrue);
      expect(repo.passwordChanges, ['token-a@b.com|Abcdef1!']);
    });

    test('si el código es inválido no cambia la contraseña', () async {
      final repo = FakeAuthRepository();

      final state = await submit(repo, code: '000000');

      expect(state.hasError, isTrue);
      expect(state.error, isA<ApiException>());
      expect(repo.passwordChanges, isEmpty);
    });
  });
}
