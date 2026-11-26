import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/cash_registers/data/models/current_shift_model.dart';
import 'package:casca_app/features/cash_registers/domain/close_shift_rules.dart';
import 'package:casca_app/features/cash_registers/domain/shift_rules.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_amounts.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_money_field.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

const int _maxNotesLength = 500;

class CloseCountStep extends StatelessWidget {
  const CloseCountStep({
    super.key,
    required this.count,
    required this.controllers,
    required this.notes,
    required this.onChanged,
  });

  final ShiftCount count;
  final Map<CountMethod, TextEditingController> controllers;
  final TextEditingController notes;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final different = count.hasDifference;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space4,
      children: [
        Text(
          'Cuenta el efectivo y los demás cobros, y compáralos con lo registrado.',
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        CascaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space4,
            children: [
              for (final method in CountMethod.values)
                _CountField(
                  method: method,
                  expected: count.expectedOf(method),
                  difference: count.differenceOf(method),
                  required: count.isRequired(method),
                  controller: controllers[method]!,
                  onChanged: onChanged,
                ),
              Divider(color: colors.border, height: CascaSpacing.space1),
              Column(
                children: [
                  ShiftAmountRow('Total esperado', count.expectedTotal),
                  ShiftAmountRow(
                    'Total contado',
                    count.countedTotal,
                    strong: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        ShiftFieldLabel(
          different ? 'Motivo de la diferencia' : 'Comentarios (opcional)',
          child: CascaInput(
            controller: notes,
            lines: 2,
            maxLength: _maxNotesLength,
            validator: (text) => different && (text ?? '').trim().isEmpty
                ? 'Explica el motivo de la diferencia'
                : null,
          ),
        ),
      ],
    );
  }
}

class _CountField extends StatelessWidget {
  const _CountField({
    required this.method,
    required this.expected,
    required this.difference,
    required this.required,
    required this.controller,
    required this.onChanged,
  });

  final CountMethod method;
  final double expected;
  final double? difference;
  final bool required;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final difference = this.difference;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space2,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: CascaSpacing.space3,
          children: [
            Text(method.label, style: textTheme.titleSmall),
            Text(
              'Esperado ${formatMoney(expected)}',
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        Semantics(
          label: 'Recuento de ${method.label}',
          child: ShiftMoneyInput(
            controller: controller,
            validator: (text) => required && parseAmount(text ?? '') == null
                ? 'Captura lo que contaste'
                : null,
            onChanged: (_) => onChanged(),
          ),
        ),
        if (difference != null)
          Align(
            alignment: Alignment.centerRight,
            child: ShiftDifference(difference),
          ),
      ],
    );
  }
}

class CloseWithdrawalStep extends StatelessWidget {
  const CloseWithdrawalStep({
    super.key,
    required this.countedCash,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final double countedCash;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final withdrawn = parseAmount(controller.text);
    final valid = isValidWithdrawal(countedCash, withdrawn);

    return CascaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          ShiftAmountRow('Efectivo contado', countedCash, strong: true),
          ShiftFieldLabel(
            '¿Cuánto retiras?',
            child: ShiftMoneyInput(
              controller: controller,
              enabled: enabled,
              validator: (text) =>
                  isValidWithdrawal(countedCash, parseAmount(text ?? ''))
                  ? null
                  : 'Escribe una cantidad entre 0 y ${formatMoney(countedCash)}',
              onChanged: (_) => onChanged(),
            ),
          ),
          ShiftAmountRow(
            'Quedará en caja',
            valid ? roundMoney(countedCash - withdrawn!) : 0,
            strong: true,
          ),
        ],
      ),
    );
  }
}

class CloseResultView extends StatelessWidget {
  const CloseResultView({
    super.key,
    required this.result,
    required this.onDone,
    this.onDetail,
  });

  final ClosedShiftModel result;
  final VoidCallback onDone;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onDetail = this.onDetail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space4,
      children: [
        const Center(
          child: CascaStatusChip(
            label: 'Corte realizado',
            tone: CascaChipTone.success,
          ),
        ),
        Text(
          'Turno cerrado',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        CascaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShiftAmountRow('Total vendido', result.totalSales),
              ShiftAmountRow('Efectivo contado', result.countedCash),
              ShiftAmountRow('Retirado al cerrar', result.withdrawnAtClose),
              ShiftAmountRow('Dejado en caja', result.leftInCash, strong: true),
              Padding(
                padding: const EdgeInsets.only(top: CascaSpacing.space3),
                child: Row(
                  spacing: CascaSpacing.space3,
                  children: [
                    Expanded(
                      child: Text(
                        'Diferencia de efectivo',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    ShiftDifference(result.difference),
                  ],
                ),
              ),
            ],
          ),
        ),
        CascaButton(label: 'Listo', fullWidth: true, onPressed: onDone),
        if (onDetail != null)
          CascaButton(
            label: 'Ver detalle del turno',
            variant: CascaButtonVariant.text,
            fullWidth: true,
            onPressed: onDetail,
          ),
      ],
    );
  }
}
