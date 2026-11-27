import 'package:casca_app/core/printing/sale_ticket.dart';

double _amount(Object? value) => (value as num?)?.toDouble() ?? 0;

class SalePreviewLineModel {
  const SalePreviewLineModel({
    required this.productId,
    required this.sellableItemId,
    required this.type,
    required this.unitPrice,
    required this.lineTotal,
    this.productVariantId,
    this.ivaType,
    this.ivaRateValue,
    this.lineIva = 0,
    this.iepsFactorType,
    this.iepsRateValue,
    this.lineIeps = 0,
  });

  factory SalePreviewLineModel.fromJson(Map<String, dynamic> json) {
    return SalePreviewLineModel(
      productId: json['productId'] as String,
      productVariantId: json['productVariantId'] as String?,
      sellableItemId: json['sellableItemId'] as String,
      type: json['type'] as int,
      unitPrice: _amount(json['unitPrice']),
      lineTotal: _amount(json['lineTotal']),
      ivaType: json['ivaType'] as int?,
      ivaRateValue: (json['ivaRateValue'] as num?)?.toDouble(),
      lineIva: _amount(json['lineIva']),
      iepsFactorType: json['iepsFactorType'] as int?,
      iepsRateValue: (json['iepsRateValue'] as num?)?.toDouble(),
      lineIeps: _amount(json['lineIeps']),
    );
  }

  final String productId;
  final String? productVariantId;
  final String sellableItemId;
  final int type;
  final double unitPrice;
  final double lineTotal;
  final int? ivaType;
  final double? ivaRateValue;
  final double lineIva;
  final int? iepsFactorType;
  final double? iepsRateValue;
  final double lineIeps;
}

class SalePreviewModel {
  const SalePreviewModel({
    required this.items,
    required this.subtotal,
    required this.finalTotal,
    this.discountTotal = 0,
    this.ivaTotal = 0,
    this.iepsTotal = 0,
    this.roundingAdjustment = 0,
  });

  factory SalePreviewModel.fromJson(Map<String, dynamic> json) {
    return SalePreviewModel(
      items: [
        for (final item in json['items'] as List<Object?>)
          SalePreviewLineModel.fromJson(item as Map<String, dynamic>),
      ],
      subtotal: _amount(json['subtotal']),
      discountTotal: _amount(json['discountTotal']),
      ivaTotal: _amount(json['ivaTotal']),
      iepsTotal: _amount(json['iepsTotal']),
      roundingAdjustment: _amount(json['roundingAdjustment']),
      finalTotal: (json['finalTotal'] as num).toDouble(),
    );
  }

  final List<SalePreviewLineModel> items;
  final double subtotal;
  final double discountTotal;
  final double ivaTotal;
  final double iepsTotal;
  final double roundingAdjustment;
  final double finalTotal;
}

class SaleResultModel {
  const SaleResultModel({
    required this.id,
    required this.saleNumber,
    required this.totalAmount,
    this.customerName,
    this.ticket,
  });

  factory SaleResultModel.fromJson(Map<String, dynamic> json) {
    return SaleResultModel(
      id: json['id'] as String,
      saleNumber: '${json['saleNumber']}',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      customerName: json['customerName'] as String?,
      ticket: SaleTicket.tryParse(json),
    );
  }

  final String id;
  final String saleNumber;
  final double totalAmount;
  final String? customerName;
  final SaleTicket? ticket;
}
