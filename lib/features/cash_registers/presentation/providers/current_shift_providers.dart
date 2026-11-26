import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/features/cash_registers/data/current_shift_repository.dart';
import 'package:casca_app/features/cash_registers/data/models/current_shift_model.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/shift_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentShiftProvider = FutureProvider.autoDispose<CurrentShiftModel?>(
  retry: (_, _) => null,
  (ref) {
    ref.watch(
      authControllerProvider.select(
        (s) => (s.session?.account.id, s.session?.activeStore.id),
      ),
    );
    return ref.watch(currentShiftRepositoryProvider).getCurrent();
  },
);

final availableRegistersProvider =
    FutureProvider.autoDispose<List<AvailableCashRegisterModel>>(
      retry: (_, _) => null,
      (ref) {
        ref.watch(
          authControllerProvider.select((s) => s.session?.activeStore.id),
        );
        return ref
            .watch(currentShiftRepositoryProvider)
            .getAvailableRegisters();
      },
    );

class ShiftActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> open(
    String cashRegisterId, {
    required double initialAmount,
    String? notes,
  }) {
    return _run(
      (repository) => repository.open(
        cashRegisterId,
        initialAmount: initialAmount,
        notes: notes,
      ),
    );
  }

  Future<bool> addMovement(
    String shiftId,
    CashMovementType type, {
    required double amount,
    required String notes,
  }) {
    return _run(
      (repository) =>
          repository.addMovement(shiftId, type, amount: amount, notes: notes),
    );
  }

  Future<bool> _run(
    Future<void> Function(CurrentShiftRepository repository) action,
  ) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final repository = ref.read(currentShiftRepositoryProvider);
    final result = await AsyncValue.guard(() => action(repository));
    if (ref.mounted) {
      ref.invalidate(currentShiftProvider);
      if (result.hasError) ref.invalidate(availableRegistersProvider);
      state = result;
    }
    keepAlive.close();
    return !result.hasError;
  }
}

final shiftActionControllerProvider =
    NotifierProvider.autoDispose<ShiftActionController, AsyncValue<void>>(
      ShiftActionController.new,
    );

class CloseShiftController extends Notifier<AsyncValue<ClosedShiftModel?>> {
  @override
  AsyncValue<ClosedShiftModel?> build() => const AsyncData(null);

  Future<void> close(
    String shiftId, {
    required double countedCash,
    required String? notes,
    required double withdrawnAtClose,
    required Map<int, double> paymentCounts,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final repository = ref.read(currentShiftRepositoryProvider);
    final result = await AsyncValue.guard<ClosedShiftModel?>(
      () => repository.close(
        shiftId,
        countedCash: countedCash,
        notes: notes,
        withdrawnAtClose: withdrawnAtClose,
        paymentCounts: paymentCounts,
      ),
    );
    if (ref.mounted) {
      state = result;
      ref.invalidate(currentShiftProvider);
      ref.invalidate(shiftListProvider);
    }
    keepAlive.close();
  }
}

final closeShiftControllerProvider =
    NotifierProvider.autoDispose<
      CloseShiftController,
      AsyncValue<ClosedShiftModel?>
    >(CloseShiftController.new);
