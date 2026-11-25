import 'package:casca_app/features/products/data/models/product_list_item_model.dart';

class ProductVariantModel {
  const ProductVariantModel({
    required this.id,
    required this.sku,
    required this.displayName,
    required this.status,
    required this.options,
    this.minimumStock = 0,
    this.maximumStock,
    this.stock = 0,
    this.saleUnit,
    this.image,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    final units = (json['saleUnits'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final main =
        units
            .where((unit) => unit['isInventoryBaseUnit'] == true)
            .firstOrNull ??
        units.firstOrNull;
    final image = json['image'] as Map<String, dynamic>?;

    return ProductVariantModel(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      status: json['status'] as int? ?? 1,
      minimumStock: (json['minimumStock'] as num?)?.toDouble() ?? 0,
      maximumStock: (json['maximumStock'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
      options: (json['options'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ProductVariantOptionModel.fromJson)
          .toList(),
      saleUnit: main == null ? null : VariantSaleUnitModel.fromJson(main),
      image: image == null ? null : ProductImageModel.fromJson(image),
    );
  }

  final String id;
  final String sku;
  final String displayName;
  final int status;
  final double minimumStock;
  final double? maximumStock;
  final double stock;
  final List<ProductVariantOptionModel> options;
  final VariantSaleUnitModel? saleUnit;
  final ProductImageModel? image;
}

class ProductVariantOptionModel {
  const ProductVariantOptionModel({
    required this.name,
    required this.value,
    this.optionPosition = 0,
    this.valuePosition = 0,
  });

  factory ProductVariantOptionModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantOptionModel(
      name: json['name'] as String,
      value: json['value'] as String,
      optionPosition: json['optionPosition'] as int? ?? 0,
      valuePosition: json['valuePosition'] as int? ?? 0,
    );
  }

  final String name;
  final String value;
  final int optionPosition;
  final int valuePosition;
}

class VariantSaleUnitModel {
  const VariantSaleUnitModel({
    required this.id,
    required this.price,
    this.displayName = '',
    this.unitOfMeasure = 0,
    this.conversionFactor = 1,
    this.affectsInventory = true,
    this.allowsDecimalQuantity = false,
    this.isInventoryBaseUnit = true,
    this.barcode,
  });

  factory VariantSaleUnitModel.fromJson(Map<String, dynamic> json) {
    return VariantSaleUnitModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
      unitOfMeasure: json['unitOfMeasure'] as int? ?? 0,
      conversionFactor: (json['conversionFactor'] as num?)?.toDouble() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      affectsInventory: json['affectsInventory'] as bool? ?? false,
      allowsDecimalQuantity: json['allowsDecimalQuantity'] as bool? ?? false,
      isInventoryBaseUnit: json['isInventoryBaseUnit'] as bool? ?? false,
      barcode: json['barcode'] as String?,
    );
  }

  final String id;
  final String displayName;
  final int unitOfMeasure;
  final double conversionFactor;
  final double price;
  final bool affectsInventory;
  final bool allowsDecimalQuantity;
  final bool isInventoryBaseUnit;
  final String? barcode;
}
