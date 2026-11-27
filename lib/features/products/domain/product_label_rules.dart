import 'package:casca_app/core/printing/product_label.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/domain/product_variant_view_rules.dart';

List<ProductLabel> productLabels(ProductDetailModel product) {
  if (product.hasVariants) {
    return [
      for (final variant in product.variants)
        if (variant.status == activeVariantStatus)
          if (variant.saleUnit case final unit?)
            ProductLabel(
              name: '${product.name} ${variant.displayName}'.trim(),
              sku: variant.sku,
              barcode: unit.barcode,
              price: unit.price,
              stock: variant.stock,
            ),
    ];
  }

  final unit = product.baseUnit;
  if (unit == null) return const [];
  return [
    ProductLabel(
      name: product.name,
      sku: product.sku,
      barcode: unit.barcode,
      price: unit.price,
      stock: product.stock ?? 0,
    ),
  ];
}

int copiesForStock(double stock) => stock.floor().clamp(0, maxLabelCopies);
