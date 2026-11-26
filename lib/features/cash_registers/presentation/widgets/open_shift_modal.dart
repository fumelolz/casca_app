import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/cash_registers/data/models/current_shift_model.dart';
import 'package:casca_app/features/cash_registers/domain/close_shift_rules.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/current_shift_providers.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_money_field.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const int _maxNotesLength = 500;

class OpenShiftModal extends ConsumerStatefulWidget {
  const OpenShiftModal({super.key});

  @override
  ConsumerState<OpenShiftModal> createState() => _OpenShiftModalState();
}

class _OpenShiftModalState extends ConsumerState<OpenShiftModal> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String? _registerId;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  AvailableCashRegisterModel? _selected(
    List<AvailableCashRegisterModel> registers,
  ) {
    for (final register in registers) {
      if (register.id == _registerId) return register;
    }
    return null;
  }

  void _select(AvailableCashRegisterModel register) {
    setState(() {
      _registerId = register.id;
      _amount.text = amountText(register.suggestedInitialAmount);
    });
  }

  void _selectInitial(List<AvailableCashRegisterModel> registers) {
    if (_registerId != null || registers.length != 1) return;
    final only = registers.single;
    _registerId = only.id;
    _amount.text = amountText(only.suggestedInitialAmount);
  }

  Future<void> _open() async {
    if (!_formKey.currentState!.validate()) return;

    final notes = _notes.text.trim();
    final opened = await ref
        .read(shiftActionControllerProvider.notifier)
        .open(
          _registerId!,
          initialAmount: parseAmount(_amount.text)!,
          notes: notes.isEmpty ? null : notes,
        );
    if (opened && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final registers = ref.watch(availableRegistersProvider);
    final action = ref.watch(shiftActionControllerProvider);
    final saving = action.isLoading;
    final items = registers.value;
    final canOpen = items != null && items.isNotEmpty;

    return CascaModal(
      title: 'Abrir turno',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: saving ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(
          label: 'Abrir turno',
          loading: saving,
          onPressed: canOpen ? _open : null,
        ),
      ],
      child: Form(key: _formKey, child: _body(context, registers, action)),
    );
  }

  Widget _body(
    BuildContext context,
    AsyncValue<List<AvailableCashRegisterModel>> registers,
    AsyncValue<void> action,
  ) {
    final actionError = action.error;
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final items = registers.value;
    final errorStyle = textTheme.bodyMedium?.copyWith(color: colors.danger);

    if (items == null) {
      final error = registers.error;
      if (error == null || registers.isLoading) {
        return const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space4,
          children: [
            CascaSkeleton(height: CascaSpacing.space8),
            CascaSkeleton(height: CascaSpacing.space8),
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CascaSpacing.space3,
        children: [
          Text(
            apiErrorMessage(
              error,
              'No fue posible obtener las cajas registradoras.',
              forbidden: 'No tienes permiso para abrir cajas registradoras.',
            ),
            style: errorStyle,
          ),
          CascaButton(
            label: 'Reintentar',
            variant: CascaButtonVariant.secondary,
            onPressed: () => ref.invalidate(availableRegistersProvider),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return Text(
        'No hay cajas disponibles para ti. Puede que todas tengan un turno '
        'abierto por otro usuario o que no tengas una caja asignada; en ese '
        'caso pide a un administrador que te dé acceso.',
        style: textTheme.bodyMedium,
      );
    }

    _selectInitial(items);
    final suggested = _selected(items)?.suggestedInitialAmount;
    final notesRequired = openingNotesRequired(
      suggested,
      parseAmount(_amount.text),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space4,
      children: [
        ShiftFieldLabel(
          'Caja registradora',
          child: CascaSelect<String>(
            options: [
              for (final register in items)
                CascaSelectOption(value: register.id, label: register.name),
            ],
            value: _registerId,
            hintText: 'Selecciona una caja',
            enabled: !action.isLoading,
            validator: (_) =>
                _selected(items) == null ? 'Selecciona una caja' : null,
            onChanged: (id) =>
                _select(items.firstWhere((register) => register.id == id)),
          ),
        ),
        ShiftFieldLabel(
          'Cantidad inicial',
          child: ShiftMoneyInput(
            controller: _amount,
            validator: (text) => parseAmount(text ?? '') == null
                ? 'Ingresa la cantidad inicial'
                : null,
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (suggested != null)
          Text(
            'En el último corte quedaron ${formatMoney(suggested)} en la caja.',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ShiftFieldLabel(
          notesRequired ? 'Motivo de la diferencia' : 'Nota (opcional)',
          child: CascaInput(
            controller: _notes,
            lines: 2,
            maxLength: _maxNotesLength,
            validator: (text) => notesRequired && (text ?? '').trim().isEmpty
                ? 'Explica por qué el monto no coincide'
                : null,
          ),
        ),
        if (actionError != null)
          Text(
            apiErrorMessage(
              actionError,
              'No fue posible abrir el turno.',
              forbidden: 'No tienes acceso a esta caja registradora.',
            ),
            style: errorStyle,
          ),
      ],
    );
  }
}
