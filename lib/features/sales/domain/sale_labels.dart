import 'package:casca_app/features/sales/data/models/sale_history_model.dart';
import 'package:casca_app/shared/formatters/payment_labels.dart';

const int cancelledSaleStatus = 1;

String saleStatusLabel(int status) {
  return switch (status) {
    0 => 'Pagada',
    cancelledSaleStatus => 'Cancelada',
    _ => 'Desconocido',
  };
}

String salePaymentsLabel(List<SalePaymentModel> payments) {
  if (payments.isEmpty) return '—';
  if (payments.length > 1) return 'Mixto';
  return salePaymentMethodLabel(payments.single.method);
}

class SaleCashSummary {
  const SaleCashSummary({required this.received, required this.change});

  final double received;
  final double change;
}

SaleCashSummary? saleCashSummary(List<SalePaymentModel> payments) {
  final cash = payments.where((payment) => payment.cashReceived != null);
  if (cash.isEmpty) return null;

  return SaleCashSummary(
    received: cash.fold(0, (sum, payment) => sum + payment.cashReceived!),
    change: cash.fold(0, (sum, payment) => sum + (payment.changeGiven ?? 0)),
  );
}
