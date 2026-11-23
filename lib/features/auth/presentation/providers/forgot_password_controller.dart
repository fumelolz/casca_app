import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordController extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  Future<void> submit(String email) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(email: email.trim().toLowerCase());
      return true;
    });
    if (!ref.mounted) return;
    state = result;
  }
}

final forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<ForgotPasswordController, AsyncValue<bool>>(
      ForgotPasswordController.new,
    );
