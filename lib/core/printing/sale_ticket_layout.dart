import 'package:casca_app/core/printing/marketing_qr.dart';
import 'package:casca_app/core/printing/sale_ticket.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/formatters/payment_labels.dart';

enum TicketTextStyle { small, normal, bold, brand }

sealed class TicketBlock {
  const TicketBlock();
}

class TicketText extends TicketBlock {
  const TicketText(
    this.text, {
    this.style = TicketTextStyle.normal,
    this.centered = false,
  });

  final String text;
  final TicketTextStyle style;
  final bool centered;
}

class TicketRow extends TicketBlock {
  const TicketRow(
    this.label,
    this.value, {
    this.style = TicketTextStyle.normal,
  });

  final String label;
  final String value;
  final TicketTextStyle style;
}

class TicketLogo extends TicketBlock {
  const TicketLogo();
}

class TicketQr extends TicketBlock {
  const TicketQr(this.modules);

  final List<String> modules;
}

class TicketSeparator extends TicketBlock {
  const TicketSeparator();
}

class TicketHeader {
  const TicketHeader({
    required this.storeName,
    this.tenantName,
    this.cashierName,
  });

  final String storeName;
  final String? tenantName;
  final String? cashierName;
}

List<TicketBlock> buildSaleTicket(
  TicketHeader header,
  SaleTicket sale, {
  DateTime? reprintedAt,
  bool duplicate = false,
}) {
  TicketText centered(
    String text, [
    TicketTextStyle style = TicketTextStyle.small,
  ]) => TicketText(text, style: style, centered: true);
  TicketRow money(String label, double amount) {
    return TicketRow(label, formatMoney(amount));
  }

  final tenant = _filled(header.tenantName);
  final cashier = _filled(header.cashierName);
  final customer = _filled(sale.customerName);
  final notes = _filled(sale.notes);
  final cash = sale.payments.where((payment) => payment.cashReceived != null);

  return [
    const TicketLogo(),
    if (tenant != null) centered(tenant, TicketTextStyle.brand),
    centered(header.storeName, TicketTextStyle.bold),
    const TicketSeparator(),
    if (duplicate) centered('*** DUPLICADO ***', TicketTextStyle.bold),
    if (reprintedAt != null)
      centered('*** REIMPRESIÓN ***', TicketTextStyle.bold),
    TicketRow('Folio:', sale.saleNumber),
    TicketRow('Fecha:', formatDateTime(sale.createdAt)),
    if (reprintedAt != null)
      TicketRow('Reimpreso:', formatDateTime(reprintedAt)),
    if (customer != null) TicketRow('Cliente:', customer),
    const TicketSeparator(),
    for (final item in sale.items) ...[
      TicketText(item.name),
      TicketRow(
        '${formatQuantity(item.quantity)} x ${formatMoney(item.unitPrice)}',
        formatMoney(item.total),
      ),
    ],
    const TicketSeparator(),
    money('Subtotal:', sale.subtotal),
    if (sale.ivaTotal != 0) money('IVA:', sale.ivaTotal),
    if (sale.iepsTotal != 0) money('IEPS:', sale.iepsTotal),
    if (sale.roundingAdjustment != 0)
      money('Redondeo:', sale.roundingAdjustment),
    TicketRow('TOTAL:', formatMoney(sale.total), style: TicketTextStyle.bold),
    const TicketSeparator(),
    const TicketText('Métodos de pago', style: TicketTextStyle.bold),
    for (final payment in sale.payments)
      money('${salePaymentMethodLabel(payment.method)}:', payment.amount),
    if (cash.isNotEmpty) ...[
      money(
        'Efectivo recibido:',
        cash.fold(0, (sum, payment) => sum + payment.cashReceived!),
      ),
      TicketRow(
        'Cambio:',
        formatMoney(
          cash.fold(0, (sum, payment) => sum + (payment.changeGiven ?? 0)),
        ),
        style: TicketTextStyle.bold,
      ),
    ],
    const TicketSeparator(),
    if (notes != null) centered(notes),
    centered('¡Gracias por su compra!', TicketTextStyle.normal),
    if (cashier != null) centered('Atendió: $cashier'),
    const TicketSeparator(),
    centered('Gestiona tu negocio con Casca'),
    centered('cascatiendas.com.mx'),
    const TicketQr(marketingQrModules),
  ];
}

String? _filled(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}
