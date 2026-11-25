import 'package:casca_app/features/cash_registers/data/cash_register_repository.dart';
import 'package:casca_app/features/cash_registers/data/models/cash_register_model.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/cash_register_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class _CashRegisterActionController
    extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> _run(
    Future<void> Function(CashRegisterRepository repository) action,
  ) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final repository = ref.read(cashRegisterRepositoryProvider);
    final result = await AsyncValue.guard(() => action(repository));
    if (ref.mounted) {
      if (!result.hasError) ref.invalidate(cashRegisterListProvider);
      state = result;
    }
    keepAlive.close();
    return !result.hasError;
  }
}

class CashRegisterFormController extends _CashRegisterActionController {
  Future<bool> save(CashRegisterRequest request, {String? cashRegisterId}) {
    return _run(
      (repository) => cashRegisterId == null
          ? repository.createCashRegister(request)
          : repository.updateCashRegister(cashRegisterId, request),
    );
  }
}

class CashRegisterDeleteController extends _CashRegisterActionController {
  Future<bool> delete(String cashRegisterId) {
    return _run((repository) => repository.deleteCashRegister(cashRegisterId));
  }
}

final cashRegisterFormControllerProvider =
    NotifierProvider.autoDispose<CashRegisterFormController, AsyncValue<void>>(
      CashRegisterFormController.new,
    );

final cashRegisterDeleteControllerProvider =
    NotifierProvider.autoDispose<
      CashRegisterDeleteController,
      AsyncValue<void>
    >(CashRegisterDeleteController.new);
