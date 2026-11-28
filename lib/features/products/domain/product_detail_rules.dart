import 'package:casca_app/features/products/data/models/inventory_movement_model.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/domain/product_form_rules.dart';
import 'package:casca_app/features/products/domain/product_list_rules.dart';

enum StockTone { good, warning, danger }

({double min, double max})? priceRange(ProductDetailModel product) {
  final prices = product.hasVariants
      ? [
          for (final variant in product.variants)
            if (variant.saleUnit case final unit?) unit.price,
        ]
      : [?product.baseUnit?.price];
  if (prices.isEmpty) return null;
  prices.sort();
  return (min: prices.first, max: prices.last);
}

double totalStock(ProductDetailModel product) {
  if (!product.hasVariants) return product.stock ?? 0;
  return product.variants.fold(0, (total, variant) => total + variant.stock);
}

StockTone stockTone(StockStatus status) => switch (status) {
  StockStatus.out || StockStatus.critical => StockTone.danger,
  StockStatus.low => StockTone.warning,
  _ => StockTone.good,
};

List<double> stockAfterEachMovement(
  List<InventoryMovementModel> newestFirst,
  double currentStock,
) {
  final result = <double>[];
  var stock = currentStock;
  for (final movement in newestFirst) {
    result.add(stock);
    stock -= movement.quantity;
  }
  return result;
}

String? ivaLabel(int code) =>
    IvaRate.values.where((rate) => rate.code == code).firstOrNull?.label;

String movementSubject(String displayName, String productName) {
  final name = displayName.trim();
  if (!name.startsWith(productName)) return name;
  final rest = name.substring(productName.length).trim();
  return rest.isEmpty ? name : rest;
}
