import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/cash_registers/data/models/cash_register_model.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/cash_register_actions_provider.dart';
import 'package:casca_app/shared/ui/casca_delete_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class CashRegisterDeleteModal extends ConsumerWidget {
  const CashRegisterDeleteModal({super.key, required this.cashRegister});

  final CashRegisterModel cashRegister;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final deleted = await ref
        .read(cashRegisterDeleteControllerProvider.notifier)
        .delete(cashRegister.id);
    if (deleted && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteState = ref.watch(cashRegisterDeleteControllerProvider);
    final error = deleteState.error;

    return CascaDeleteModal(
      title: '¿Eliminar ${cashRegister.name}?',
      message: 'Esta acción no se puede deshacer. Solo se eliminan cajas cerradas y sin turnos registrados.',
      deleting: deleteState.isLoading,
      errorMessage: error == null
          ? null
          : apiErrorMessage(
              error,
              'No fue posible eliminar la caja registradora.',
              forbidden: 'No tienes permiso para eliminar cajas registradoras.',
            ),
      onConfirm: () => _delete(context, ref),
    );
  }
}
