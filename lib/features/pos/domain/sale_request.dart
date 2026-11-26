import 'dart:math';

import 'package:casca_app/features/pos/domain/cart_rules.dart';
import 'package:casca_app/features/pos/domain/payment_rules.dart';

const int _keyBytes = 16;

Map<String, dynamic> _itemRequest(CartLine line) {
  return {
    'productId': line.item.productId,
    'productVariantId': line.item.productVariantId,
    'sellableItemId': line.item.sellableItemId,
    'type': line.item.type,
    'quantity': line.quantity,
    'customPrice': line.customPrice,
    'priceListId': line.priceListId,
  };
}

Map<String, dynamic> previewRequest(List<CartLine> lines, String? priceListId) {
  return {
    'items': [for (final line in lines) _itemRequest(line)],
    'priceListId': priceListId,
  };
}

Map<String, dynamic> saleRequest(
  List<CartLine> lines,
  Payment payment, {
  String? priceListId,
}) {
  return {
    'customerId': null,
    'payments': [
      for (final part in payment.lines)
        {
          'method': part.method.code,
          'amount': part.amountCents / 100,
          if (part.receivedCents != null)
            'cashReceived': part.receivedCents! / 100,
        },
    ],
    'notes': '',
    'items': [for (final line in lines) _itemRequest(line)],
    'priceListId': priceListId,
  };
}

String newIdempotencyKey([Random? random]) {
  final source = random ?? Random.secure();
  return [
    for (var i = 0; i < _keyBytes; i++)
      source.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
