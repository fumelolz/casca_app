import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/cash_registers/data/models/current_shift_model.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_amounts.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

const Duration _expandDuration = Duration(milliseconds: 200);

class CurrentCashCard extends StatefulWidget {
  const CurrentCashCard({
    super.key,
    required this.shift,
    this.onDeposit,
    this.onWithdraw,
  });

  final CurrentShiftModel shift;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;

  @override
  State<CurrentCashCard> createState() => _CurrentCashCardState();
}

class _CurrentCashCardState extends State<CurrentCashCard> {
  bool _expanded = false;

  String _openingLabel(CurrentShiftModel shift) {
    final previous = shift.previousClosedByUserName;
    final left = shift.expectedOpeningAmount;
    final author = previous == null ? '' : ' de $previous';
    final amount = left == null ? '' : ' dejó ${formatMoney(left)}';
    return 'Diferencia de apertura (último corte$author$amount)';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final shift = widget.shift;
    final summary = shift.summary;
    final opening = shift.openingDifference;
    final notes = shift.openingNotes;
    final onDeposit = widget.onDeposit;
    final onWithdraw = widget.onWithdraw;

    return CascaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          Column(
            children: [
              Text(
                'Efectivo esperado en caja',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Text(
                formatMoney(summary.expectedCash),
                style: textTheme.headlineLarge,
              ),
            ],
          ),
          if (onDeposit != null && onWithdraw != null)
            Row(
              spacing: CascaSpacing.space3,
              children: [
                Expanded(
                  child: CascaButton(
                    label: 'Ingresar',
                    variant: CascaButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: onDeposit,
                  ),
                ),
                Expanded(
                  child: CascaButton(
                    label: 'Retirar',
                    variant: CascaButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: onWithdraw,
                  ),
                ),
              ],
            ),
          Divider(color: colors.border, height: CascaSpacing.space1),
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: CascaSpacing.space2,
                ),
                child: Row(
                  spacing: CascaSpacing.space3,
                  children: [
                    Expanded(
                      child: Text(
                        'Cómo se calcula',
                        style: textTheme.titleSmall,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : _expandDuration,
                      child: CascaIcon(
                        CascaIcons.chevronDown,
                        size: CascaSpacing.space4,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShiftAmountRow('Fondo inicial', shift.initialAmount),
                if (opening != null && opening != 0)
                  ShiftAmountRow(_openingLabel(shift), opening),
                ShiftAmountRow('Ventas en efectivo', summary.cashSales),
                ShiftAmountRow('Ingresos de efectivo', summary.cashIn),
                ShiftAmountRow('Retiros de efectivo', summary.cashOut),
                if (notes != null && notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: CascaSpacing.space3),
                    child: Text(
                      'Nota de apertura: $notes',
                      style: textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class CurrentSalesCard extends StatelessWidget {
  const CurrentSalesCard({super.key, required this.summary});

  final CurrentShiftSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return CascaCard(
      title: 'Ventas del turno',
      child: Column(
        children: [
          ShiftAmountRow('Efectivo', summary.cashSales),
          ShiftAmountRow('Transferencia', summary.transferSales),
          ShiftAmountRow('Tarjeta de Crédito', summary.creditCardSales),
          ShiftAmountRow('Tarjeta de Débito', summary.debitCardSales),
          Divider(color: context.casca.border),
          ShiftAmountRow('Total vendido', summary.totalSales, strong: true),
        ],
      ),
    );
  }
}
