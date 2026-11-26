import 'package:casca_app/features/cash_registers/data/models/shift_model.dart';

const int _cashMethod = 0;
const List<(int, String)> _countedMethods = [
  (_cashMethod, 'Efectivo'),
  (4, 'Tarjeta de Crédito'),
  (3, 'Tarjeta de Débito'),
  (1, 'Transferencia'),
];

double roundMoney(double value) => (value * 100).round() / 100;

String paymentMethodLabel(String method) {
  return switch (method) {
    'Cash' => 'Efectivo',
    'BankTransfer' => 'Transferencia',
    'Check' => 'Cheque',
    'DebitCard' => 'Tarjeta de Débito',
    'CreditCard' => 'Tarjeta de Crédito',
    'Points' => 'Puntos',
    _ => method,
  };
}

String movementLabel(String type) {
  return switch (type) {
    'Opening' => 'Apertura',
    'SaleCash' => 'Venta en efectivo',
    'Withdrawal' => 'Retiro',
    'Deposit' => 'Ingreso',
    'Adjustment' => 'Ajuste',
    _ => type,
  };
}

double expectedCash(ShiftDetailModel detail) {
  final summary = detail.summary;
  return detail.shift.expectedCash ??
      roundMoney(
        detail.shift.initialAmount +
            summary.cashSales +
            summary.cashIn -
            summary.cashOut,
      );
}

class ShiftCountRow {
  const ShiftCountRow({
    required this.label,
    required this.expected,
    required this.counted,
  });

  final String label;
  final double expected;
  final double counted;

  double get difference => roundMoney(counted - expected);
}

List<ShiftCountRow> closedShiftCounts(ShiftDetailModel detail) {
  final expected = detail.shift.expectedCash;
  final counted = detail.shift.countedCash;
  if (detail.shift.closedAt == null || expected == null || counted == null) {
    return const [];
  }

  final amounts = {
    _cashMethod: (expected, counted),
    for (final count in detail.paymentCounts)
      count.method: (count.expected, count.counted),
  };

  return [
    for (final (method, label) in _countedMethods)
      if (amounts[method] case final amount?)
        ShiftCountRow(label: label, expected: amount.$1, counted: amount.$2),
  ];
}

ShiftCountRow totalCount(List<ShiftCountRow> rows) {
  return ShiftCountRow(
    label: 'Total',
    expected: roundMoney(rows.fold(0, (sum, row) => sum + row.expected)),
    counted: roundMoney(rows.fold(0, (sum, row) => sum + row.counted)),
  );
}
