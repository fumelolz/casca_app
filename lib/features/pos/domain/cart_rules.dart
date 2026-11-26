import 'dart:math' as math;

import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/data/models/sale_model.dart';

const int _quantityDecimals = 3;
const int _amountDecimals = 2;

const String publicPriceListId = '00000000-0000-0000-0000-000000000000';

class LinePricing {
  const LinePricing({this.customPrice, this.priceListId});

  final double? customPrice;
  final String? priceListId;
}

class CartLine {
  const CartLine({
    required this.item,
    required this.quantity,
    this.customPrice,
    this.priceListId,
  });

  final PosCatalogItemModel item;
  final double quantity;
  final double? customPrice;
  final String? priceListId;

  String get key => cartKey(
    item.productId,
    item.productVariantId,
    item.sellableItemId,
    item.type,
  );

  CartLine withQuantity(double quantity) {
    return CartLine(
      item: item,
      quantity: quantity,
      customPrice: customPrice,
      priceListId: priceListId,
    );
  }

  CartLine withPricing(LinePricing pricing) {
    return CartLine(
      item: item,
      quantity: quantity,
      customPrice: pricing.customPrice,
      priceListId: pricing.priceListId,
    );
  }
}

bool canTotalLocally(List<CartLine> lines, String? salePriceListId) {
  return salePriceListId == null &&
      lines.every(
        (line) => line.priceListId == null && !line.item.fromPriceList,
      );
}

String cartKey(
  String productId,
  String? productVariantId,
  String sellableItemId,
  int type,
) {
  return '$productId|${productVariantId ?? ''}|$sellableItemId|$type';
}

bool isAvailable(PosCatalogItemModel item) {
  return !item.affectsInventory || item.quantity > 0;
}

bool isValidQuantity(PosCatalogItemModel item, double quantity) {
  return quantity.isFinite &&
      quantity > 0 &&
      (item.allowsDecimalQuantity || quantity == quantity.roundToDouble());
}

double roundTo(double value, int decimals) {
  final factor = math.pow(10, decimals);
  return (value * factor).round() / factor;
}

double roundQuantity(double quantity) {
  return roundTo(quantity, _quantityDecimals);
}

double estimateAmount(double quantity, double unitPrice) {
  return roundTo(quantity * unitPrice, _amountDecimals);
}

double? quantityForAmount(double amount, double unitPrice) {
  if (unitPrice <= 0) return null;
  final quantity = roundQuantity(amount / unitPrice);
  return quantity > 0 ? quantity : null;
}

double maxQuantity(List<CartLine> lines, PosCatalogItemModel item, String key) {
  if (!item.affectsInventory || item.conversionFactor <= 0) {
    return double.infinity;
  }

  final reservedByOthers = lines
      .where((line) => line.key != key && line.item.id == item.id)
      .fold(
        0.0,
        (sum, line) => sum + line.quantity * line.item.conversionFactor,
      );
  final available = (item.quantity - reservedByOthers) / item.conversionFactor;
  final precision = item.allowsDecimalQuantity ? 1000 : 1;

  return math.max(0, (available * precision + 1e-6).floor() / precision);
}

SalePreviewModel untaxedPreview(List<CartLine> lines) {
  final items = [
    for (final line in lines)
      SalePreviewLineModel(
        productId: line.item.productId,
        productVariantId: line.item.productVariantId,
        sellableItemId: line.item.sellableItemId,
        type: line.item.type,
        unitPrice: line.customPrice ?? line.item.price,
        lineTotal: estimateAmount(
          line.quantity,
          line.customPrice ?? line.item.price,
        ),
      ),
  ];
  final total = roundTo(
    items.fold(0.0, (sum, line) => sum + line.lineTotal),
    _amountDecimals,
  );

  return SalePreviewModel(items: items, subtotal: total, finalTotal: total);
}
