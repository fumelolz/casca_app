double _amount(Object? value) => (value as num?)?.toDouble() ?? 0;

class TicketItem {
  const TicketItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String name;
  final double quantity;
  final double unitPrice;
  final double total;
}

class TicketPayment {
  const TicketPayment({
    required this.method,
    required this.amount,
    this.cashReceived,
    this.changeGiven,
  });

  final int method;
  final double amount;
  final double? cashReceived;
  final double? changeGiven;
}

class SaleTicket {
  const SaleTicket({
    required this.saleNumber,
    required this.createdAt,
    required this.items,
    required this.payments,
    required this.subtotal,
    required this.total,
    this.ivaTotal = 0,
    this.iepsTotal = 0,
    this.roundingAdjustment = 0,
    this.customerName,
    this.notes,
  });

  static SaleTicket? tryParse(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdOnUtc'] as String? ?? '');
    final items = json['items'] as List<Object?>?;
    if (createdAt == null || items == null || items.isEmpty) return null;
    final payments = json['payments'] as List<Object?>? ?? const [];

    return SaleTicket(
      saleNumber: '${json['saleNumber']}',
      createdAt: createdAt,
      items: [
        for (final item in items.cast<Map<String, dynamic>>())
          TicketItem(
            name: item['displayName'] as String? ?? '',
            quantity: _amount(item['quantity']),
            unitPrice: _amount(item['unitPrice']),
            total: _amount(item['total']),
          ),
      ],
      payments: [
        for (final payment in payments.cast<Map<String, dynamic>>())
          TicketPayment(
            method: payment['method'] as int,
            amount: _amount(payment['amount']),
            cashReceived: (payment['cashReceived'] as num?)?.toDouble(),
            changeGiven: (payment['changeGiven'] as num?)?.toDouble(),
          ),
      ],
      subtotal: _amount(json['subtotal']),
      ivaTotal: _amount(json['ivaTotal']),
      iepsTotal: _amount(json['iepsTotal']),
      roundingAdjustment: _amount(json['roundingAdjustment']),
      total: _amount(json['totalAmount']),
      customerName: json['customerName'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String saleNumber;
  final DateTime createdAt;
  final List<TicketItem> items;
  final List<TicketPayment> payments;
  final double subtotal;
  final double ivaTotal;
  final double iepsTotal;
  final double roundingAdjustment;
  final double total;
  final String? customerName;
  final String? notes;
}
