import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SetPasswordController extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() => const AsyncData(false);

  Future<void> submit({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final sessionToken = await repository.verifyResetCode(
        email: email.trim(),
        code: code.trim(),
      );
      await repository.changePassword(
        sessionToken: sessionToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return true;
    });
    if (!ref.mounted) return;
    state = result;
  }
}

final setPasswordControllerProvider =
    NotifierProvider.autoDispose<SetPasswordController, AsyncValue<bool>>(
      SetPasswordController.new,
    );
