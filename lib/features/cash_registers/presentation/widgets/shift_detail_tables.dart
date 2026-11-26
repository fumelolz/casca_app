import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/features/cash_registers/data/models/shift_model.dart';
import 'package:casca_app/features/cash_registers/domain/shift_rules.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/shift_providers.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:material_ui/material_ui.dart';

CascaTableColumn<T> _amountColumn<T>(
  String header,
  double Function(T row) amount,
) {
  return CascaTableColumn(
    id: 'amount',
    header: header,
    flex: 2,
    align: CascaTableAlign.end,
    showOnCompact: true,
    cellBuilder: (context, row) => Text(
      formatMoney(amount(row)),
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space3,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        child,
      ],
    );
  }
}

class ShiftMovementsTable extends StatelessWidget {
  const ShiftMovementsTable({
    super.key,
    required this.movements,
    required this.page,
    required this.totalItems,
    required this.loading,
    required this.onPageChanged,
  });

  final List<ShiftMovementModel> movements;
  final int page;
  final int totalItems;
  final bool loading;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Movimientos de efectivo',
      child: CascaTable<ShiftMovementModel>(
        columns: [
          CascaTableColumn(
            id: 'movement',
            header: 'Movimiento',
            flex: 3,
            showOnCompact: true,
            cellBuilder: (context, movement) => CascaTableTwoLineCell(
              title: movementLabel(movement.type),
              subtitle: [
                formatDateTime(movement.createdAt),
                if (movement.userName.isNotEmpty) movement.userName,
              ].join(' · '),
            ),
          ),
          CascaTableColumn(
            id: 'notes',
            header: 'Notas',
            flex: 3,
            cellBuilder: (context, movement) => Text(
              movement.notes ?? '—',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _amountColumn('Monto', (movement) => movement.amount),
        ],
        rows: movements,
        rowKey: (movement) =>
            '${movement.createdAt.microsecondsSinceEpoch}-${movement.type}-${movement.amount}',
        loading: loading,
        emptyTitle: 'No hay movimientos de efectivo en este turno.',
        page: page,
        pageSize: shiftDetailPageSize,
        totalItems: totalItems,
        onPageChanged: onPageChanged,
      ),
    );
  }
}

class ShiftSalesTable extends StatelessWidget {
  const ShiftSalesTable({
    super.key,
    required this.sales,
    required this.page,
    required this.totalItems,
    required this.loading,
    required this.onPageChanged,
    this.onSaleTap,
  });

  final List<ShiftSaleModel> sales;
  final int page;
  final int totalItems;
  final bool loading;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ShiftSaleModel>? onSaleTap;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Ventas del turno',
      child: CascaTable<ShiftSaleModel>(
        columns: [
          CascaTableColumn(
            id: 'sale',
            header: 'Venta',
            flex: 3,
            showOnCompact: true,
            cellBuilder: (context, sale) => CascaTableTwoLineCell(
              title: sale.saleNumber,
              subtitle: formatDateTime(sale.createdAt),
            ),
          ),
          CascaTableColumn(
            id: 'payments',
            header: 'Método de pago',
            flex: 3,
            showOnCompact: true,
            cellBuilder: (context, sale) => Text(
              [
                for (final payment in sale.payments)
                  '${paymentMethodLabel(payment.method)}: '
                      '${formatMoney(payment.amount)}',
              ].join('\n'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _amountColumn('Total', (sale) => sale.total),
        ],
        rows: sales,
        rowKey: (sale) => sale.id,
        onRowTap: onSaleTap,
        loading: loading,
        emptyTitle: 'No hay ventas asociadas a este turno.',
        page: page,
        pageSize: shiftDetailPageSize,
        totalItems: totalItems,
        onPageChanged: onPageChanged,
      ),
    );
  }
}
