import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/cash_registers/data/models/shift_model.dart';
import 'package:casca_app/features/cash_registers/domain/shift_rules.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_amounts.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

class ShiftHeaderCard extends StatelessWidget {
  const ShiftHeaderCard({super.key, required this.shift});

  final ShiftInfoModel shift;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: context.casca.textSecondary,
    );
    final closedAt = shift.closedAt;
    final closedBy = shift.closedByUserName;

    return CascaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CascaSpacing.space1,
        children: [
          Row(
            spacing: CascaSpacing.space3,
            children: [
              Expanded(
                child: Text(
                  shift.cashRegisterName,
                  style: textTheme.titleLarge,
                ),
              ),
              CascaStatusChip(
                label: closedAt == null ? 'Turno abierto' : 'Turno cerrado',
                tone: closedAt == null
                    ? CascaChipTone.success
                    : CascaChipTone.neutral,
              ),
            ],
          ),
          Text(shift.userName, style: textTheme.bodyMedium),
          Text('Apertura: ${formatDateTime(shift.openedAt)}', style: muted),
          if (closedAt != null)
            Text('Cierre: ${formatDateTime(closedAt)}', style: muted),
          if (closedBy != null && closedBy != shift.userName)
            Text('Cerrado por: $closedBy', style: muted),
        ],
      ),
    );
  }
}

class ShiftSalesCard extends StatelessWidget {
  const ShiftSalesCard({super.key, required this.summary});

  final ShiftSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return CascaCard(
      title: 'Ventas registradas',
      child: Column(
        children: [
          ShiftAmountRow('Efectivo', summary.cashSales),
          ShiftAmountRow('No efectivo', summary.nonCashSales),
          Divider(color: context.casca.border),
          ShiftAmountRow('Total vendido', summary.totalSales, strong: true),
        ],
      ),
    );
  }
}

class ShiftCashCard extends StatelessWidget {
  const ShiftCashCard({super.key, required this.detail});

  final ShiftDetailModel detail;

  String _openingLabel(ShiftInfoModel shift) {
    final previous = shift.previousClosedByUserName;
    final left = shift.expectedOpeningAmount;
    final author = previous == null ? '' : ' de $previous';
    final amount = left == null ? '' : ' dejó ${formatMoney(left)}';
    return 'Diferencia de apertura (último corte$author$amount)';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shift = detail.shift;
    final summary = detail.summary;
    final opening = shift.openingDifference;
    final counted = shift.countedCash;
    final withdrawn = shift.withdrawnAtClose;
    final left = shift.leftInCash;
    final difference = shift.difference;
    final openingNotes = shift.openingNotes;
    final closingNotes = shift.closingNotes;

    return CascaCard(
      title: 'Efectivo en caja',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShiftAmountRow('Fondo inicial', shift.initialAmount),
          if (opening != null && opening != 0)
            ShiftAmountRow(_openingLabel(shift), opening),
          ShiftAmountRow('Ventas en efectivo', summary.cashSales),
          ShiftAmountRow('Ingresos de efectivo', summary.cashIn),
          ShiftAmountRow('Retiros de efectivo', summary.cashOut),
          Divider(color: context.casca.border),
          ShiftAmountRow(
            'Efectivo esperado',
            expectedCash(detail),
            strong: true,
          ),
          if (counted != null) ShiftAmountRow('Efectivo contado', counted),
          if (withdrawn != null)
            ShiftAmountRow('Retirado al cerrar', withdrawn),
          if (left != null) ShiftAmountRow('Dejado en caja', left),
          if (difference != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: CascaSpacing.space1,
              ),
              child: Row(
                spacing: CascaSpacing.space3,
                children: [
                  Expanded(
                    child: Text(
                      'Diferencia de caja',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  ShiftDifference(difference),
                ],
              ),
            ),
          if (openingNotes != null && openingNotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: CascaSpacing.space3),
              child: Text(
                'Nota de apertura: $openingNotes',
                style: textTheme.bodySmall,
              ),
            ),
          if (closingNotes != null && closingNotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: CascaSpacing.space3),
              child: Text(
                'Nota de cierre: $closingNotes',
                style: textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class ShiftCountsCard extends StatelessWidget {
  const ShiftCountsCard({super.key, required this.rows});

  final List<ShiftCountRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    Widget row(ShiftCountRow count, {bool strong = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CascaSpacing.space3,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.label,
                    style: strong
                        ? textTheme.titleMedium
                        : textTheme.bodyMedium,
                  ),
                  Text(
                    'Esperado ${formatMoney(count.expected)} · '
                    'Contado ${formatMoney(count.counted)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ShiftDifference(count.difference),
          ],
        ),
      );
    }

    return CascaCard(
      title: 'Corte por método de pago',
      child: Column(
        children: [
          for (final count in rows) row(count),
          Divider(color: colors.border),
          row(totalCount(rows), strong: true),
        ],
      ),
    );
  }
}
