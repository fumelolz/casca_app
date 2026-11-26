import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/cash_registers/data/current_shift_repository.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/current_shift_providers.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_money_field.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const int _maxNotesLength = 500;

class CashMovementModal extends ConsumerStatefulWidget {
  const CashMovementModal({
    super.key,
    required this.shiftId,
    required this.type,
  });

  final String shiftId;
  final CashMovementType type;

  @override
  ConsumerState<CashMovementModal> createState() => _CashMovementModalState();
}

class _CashMovementModalState extends ConsumerState<CashMovementModal> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  bool get _isDeposit => widget.type == CashMovementType.deposit;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final saved = await ref
        .read(shiftActionControllerProvider.notifier)
        .addMovement(
          widget.shiftId,
          widget.type,
          amount: parseAmount(_amount.text)!,
          notes: _notes.text.trim(),
        );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(shiftActionControllerProvider);
    final saving = action.isLoading;
    final error = action.error;
    final title = _isDeposit ? 'Ingresar dinero' : 'Retirar dinero';

    return CascaModal(
      title: title,
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: saving ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(label: title, loading: saving, onPressed: _save),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space4,
          children: [
            ShiftFieldLabel(
              'Cantidad',
              child: ShiftMoneyInput(
                controller: _amount,
                autofocus: true,
                validator: (text) => (parseAmount(text ?? '') ?? 0) <= 0
                    ? 'Ingresa una cantidad mayor a cero'
                    : null,
              ),
            ),
            ShiftFieldLabel(
              'Motivo',
              child: CascaInput(
                controller: _notes,
                lines: 3,
                maxLength: _maxNotesLength,
                hintText: _isDeposit
                    ? 'Motivo del ingreso de efectivo'
                    : 'Motivo del retiro de efectivo',
                validator: (text) =>
                    (text ?? '').trim().isEmpty ? 'Escribe el motivo' : null,
              ),
            ),
            if (error != null)
              Text(
                apiErrorMessage(
                  error,
                  _isDeposit
                      ? 'No fue posible registrar el ingreso de efectivo.'
                      : 'No fue posible registrar el retiro de efectivo.',
                  forbidden: 'No tienes permiso para mover efectivo.',
                ),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.casca.danger),
              ),
          ],
        ),
      ),
    );
  }
}
