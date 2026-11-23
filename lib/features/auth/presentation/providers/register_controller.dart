import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/register_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit(RegisterRequest request) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authControllerProvider.notifier).register(request),
    );
    if (!ref.mounted) return;
    state = result;
  }
}

final registerControllerProvider =
    NotifierProvider.autoDispose<RegisterController, AsyncValue<void>>(
      RegisterController.new,
    );
