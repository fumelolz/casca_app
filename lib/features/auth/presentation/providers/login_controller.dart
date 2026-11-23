import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({required String email, required String password}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(authControllerProvider.notifier)
          .signIn(email: email, password: password),
    );
    if (!ref.mounted) return;
    state = result;
  }
}

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, AsyncValue<void>>(
      LoginController.new,
    );
