import 'package:casca_app/core/printing/sale_ticket.dart';

double _amount(Object? value) => (value as num?)?.toDouble() ?? 0;

DateTime? _date(Object? value) {
  return value == null ? null : DateTime.parse(value as String);
}

List<T> _items<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  return [
    for (final item in (value as List<Object?>?) ?? const [])
      fromJson(item as Map<String, dynamic>),
  ];
}

class SalePaymentModel {
  const SalePaymentModel({
    required this.method,
    required this.amount,
    this.cashReceived,
    this.changeGiven,
  });

  factory SalePaymentModel.fromJson(Map<String, dynamic> json) {
    return SalePaymentModel(
      method: json['method'] as int,
      amount: _amount(json['amount']),
      cashReceived: (json['cashReceived'] as num?)?.toDouble(),
      changeGiven: (json['changeGiven'] as num?)?.toDouble(),
    );
  }

  final int method;
  final double amount;
  final double? cashReceived;
  final double? changeGiven;
}

class SaleListItemModel {
  const SaleListItemModel({
    required this.id,
    required this.saleNumber,
    required this.status,
    required this.payments,
    required this.total,
    this.createdAt,
  });

  factory SaleListItemModel.fromJson(Map<String, dynamic> json) {
    return SaleListItemModel(
      id: json['id'] as String,
      saleNumber: json['saleNumber'] as String,
      status: json['status'] as int,
      payments: _items(json['payments'], SalePaymentModel.fromJson),
      total: _amount(json['totalAmount']),
      createdAt: _date(json['createdOnUtc']),
    );
  }

  final String id;
  final String saleNumber;
  final int status;
  final List<SalePaymentModel> payments;
  final double total;
  final DateTime? createdAt;
}

class SaleLineModel {
  const SaleLineModel({
    required this.id,
    required this.name,
    required this.unitName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.total,
  });

  factory SaleLineModel.fromJson(Map<String, dynamic> json) {
    return SaleLineModel(
      id: json['id'] as String,
      name: json['displayName'] as String,
      unitName: json['saleUnitName'] as String? ?? '',
      quantity: _amount(json['quantity']),
      unitPrice: _amount(json['unitPrice']),
      subtotal: _amount(json['subtotal']),
      total: _amount(json['total']),
    );
  }

  final String id;
  final String name;
  final String unitName;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final double total;
}

class SaleDetailModel {
  const SaleDetailModel({
    required this.saleNumber,
    required this.status,
    required this.payments,
    required this.subtotal,
    required this.total,
    required this.createdAt,
    required this.items,
    this.modifiedAt,
    this.notes,
    this.customerName,
    this.ticket,
  });

  factory SaleDetailModel.fromJson(Map<String, dynamic> json) {
    return SaleDetailModel(
      saleNumber: json['saleNumber'] as String,
      status: json['status'] as int,
      payments: _items(json['payments'], SalePaymentModel.fromJson),
      subtotal: _amount(json['subtotal']),
      total: _amount(json['totalAmount']),
      createdAt: DateTime.parse(json['createdOnUtc'] as String),
      modifiedAt: _date(json['modifiedOnUtc']),
      notes: json['notes'] as String?,
      customerName: json['customerName'] as String?,
      items: _items(json['items'], SaleLineModel.fromJson),
      ticket: SaleTicket.tryParse(json),
    );
  }

  final String saleNumber;
  final int status;
  final List<SalePaymentModel> payments;
  final double subtotal;
  final double total;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final String? notes;
  final String? customerName;
  final List<SaleLineModel> items;
  final SaleTicket? ticket;
}
