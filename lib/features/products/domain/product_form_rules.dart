import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/domain/product_variant_rules.dart';

enum ProductKind {
  product(0, 'Producto'),
  service(1, 'Servicio');

  const ProductKind(this.code, this.label);

  final int code;
  final String label;
}

enum ProductUnit {
  piece(0, 'Pieza', 'pzs'),
  kilogram(1, 'Kilogramo', 'kg'),
  meter(2, 'Metro', 'm');

  const ProductUnit(this.code, this.label, this.symbol);

  final int code;
  final String label;
  final String symbol;

  bool get allowsDecimals => this != piece;
}

enum IvaRate {
  rate16(0, 'IVA 16%'),
  rate8(1, 'IVA 8%'),
  rate0(2, 'IVA 0%'),
  exempt(3, 'Exento');

  const IvaRate(this.code, this.label);

  final int code;
  final String label;
}

enum IepsRate {
  none(0, 'No aplica'),
  highCalorieFood(1, 'Alimentos de alta densidad calórica (8%)'),
  energyDrinks(2, 'Bebidas energizantes (25%)'),
  alcohol265(3, 'Bebidas hasta 14° G.L. (26.5%)'),
  alcohol30(4, 'Bebidas de 14° a 20° G.L. (30%)'),
  alcohol53(5, 'Bebidas de más de 20° G.L. (53%)'),
  denaturedAlcohol(6, 'Alcohol y mieles (50%)'),
  tobacco(7, 'Tabacos labrados (160%)'),
  flavoredDrinks(8, 'Bebidas saborizadas (cuota por litro)'),
  pesticides6(9, 'Plaguicidas (6%)'),
  pesticides7(10, 'Plaguicidas (7%)'),
  pesticides9(11, 'Plaguicidas (9%)');

  const IepsRate(this.code, this.label);

  final int code;
  final String label;

  bool get needsQuantity => this == flavoredDrinks;
}

const int _serviceSatUnit = 1;
const int _productSatUnit = 0;

class ProductFormValues {
  const ProductFormValues({
    required this.kind,
    required this.name,
    required this.categoryId,
    this.description = '',
    this.unit = ProductUnit.piece,
    this.barcode = '',
    this.price = 0,
    this.iva = IvaRate.rate16,
    this.ieps = IepsRate.none,
    this.iepsQuantity,
    this.cost = 0,
    this.initialStock = 0,
    this.minimumStock = 0,
    this.maximumStock,
    this.variants = const [],
  });

  final List<ProductVariantDraft> variants;
  final ProductKind kind;
  final String name;
  final String categoryId;
  final String description;
  final ProductUnit unit;
  final String barcode;
  final double price;
  final IvaRate iva;
  final IepsRate ieps;
  final double? iepsQuantity;
  final double cost;
  final double initialStock;
  final double minimumStock;
  final double? maximumStock;

  bool get isService => kind == ProductKind.service;
}

String? _textOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> toCreateProductRequest(ProductFormValues values) {
  final service = values.isService;
  final unit = service ? ProductUnit.piece : values.unit;
  final variants = service ? const <ProductVariantDraft>[] : values.variants;
  final ownStock = !service && variants.isEmpty;

  return {
    'hasInitialStock': ownStock && values.initialStock > 0,
    'brandId': null,
    'customBrandName': null,
    'name': values.name.trim(),
    'description': _textOrNull(values.description),
    'productType': values.kind.code,
    'categoryId': values.categoryId,
    'productTemplateId': null,
    'minimumStock': ownStock ? values.minimumStock : 0,
    'maximumStock': ownStock ? values.maximumStock : null,
    'initialStock': ownStock ? values.initialStock : 0,
    'unitCost': ownStock ? values.cost : 0,
    'defaultTaxRate': values.iva.code,
    'defaultIepsTaxRate': values.ieps.code,
    'iepsQuantityFactor': values.ieps.needsQuantity
        ? values.iepsQuantity
        : null,
    'satUnitCode': service ? _serviceSatUnit : _productSatUnit,
    'satProductServiceCode': null,
    'variants': [for (final variant in variants) toVariantRequest(variant)],
    'saleUnits': [
      if (variants.isEmpty)
        {
          'unitOfMeasure': unit.code,
          'conversionFactor': 1,
          'price': values.price,
          'affectsInventory': !service,
          'allowsDecimalQuantity': !service && unit.allowsDecimals,
          'isInventoryBaseUnit': true,
          'barcode': service ? null : _textOrNull(values.barcode),
          'cost': service ? values.cost : 0,
        },
    ],
  };
}

bool managesStockLimits(ProductDetailModel product) {
  return product.productType != ProductKind.service.code &&
      !product.hasVariants;
}

Map<String, dynamic> toUpdateProductRequest(
  ProductFormValues values,
  ProductDetailModel current,
) {
  final limits = managesStockLimits(current);

  return {
    'brandId': current.brandId,
    'customBrandName': current.brandId == null ? current.brandName : null,
    'name': values.name.trim(),
    'description': _textOrNull(values.description),
    'productType': current.productType,
    'categoryId': values.categoryId,
    'version': current.version,
    'defaultTaxRate': values.iva.code,
    'defaultIepsTaxRate': values.ieps.code,
    'iepsQuantityFactor': values.ieps.needsQuantity
        ? values.iepsQuantity
        : null,
    'satUnitCode': current.satUnitCode,
    'satProductServiceCode': null,
    'minimumStock': limits ? values.minimumStock : null,
    'maximumStock': limits ? values.maximumStock : null,
  };
}

double? parseAmount(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final number = double.tryParse(text);
  return number == null || number < 0 ? null : number;
}

String? validateProductName(String? value) {
  return (value?.trim() ?? '').isEmpty ? 'Ingresa el nombre' : null;
}

String? validatePrice(String? value) {
  if ((value?.trim() ?? '').isEmpty) return 'Ingresa el precio';
  return parseAmount(value) == null ? 'Ingresa un número válido' : null;
}

String? validateOptionalAmount(String? value) {
  if ((value?.trim() ?? '').isEmpty) return null;
  return parseAmount(value) == null ? 'Ingresa un número válido' : null;
}

String? validateCost(String? value, {required double initialStock}) {
  final error = validateOptionalAmount(value);
  if (error != null) return error;
  if (initialStock > 0 && (parseAmount(value) ?? 0) <= 0) {
    return 'El stock inicial necesita un costo';
  }
  return null;
}

String? validateMaximumStock(String? value, {required double minimumStock}) {
  final error = validateOptionalAmount(value);
  if (error != null) return error;
  final maximum = parseAmount(value);
  if (maximum != null && maximum <= minimumStock) {
    return 'Debe ser mayor que el mínimo';
  }
  return null;
}
