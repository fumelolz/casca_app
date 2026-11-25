import 'package:casca_app/features/products/data/models/product_list_item_model.dart';

class ProductDetailModel {
  const ProductDetailModel({
    required this.id,
    required this.name,
    required this.productType,
    required this.version,
    required this.ivaRate,
    required this.iepsRate,
    required this.satUnitCode,
    required this.hasVariants,
    this.description,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
    this.iepsQuantityFactor,
    this.minimumStock,
    this.maximumStock,
    this.averageCost,
    this.stock,
    this.baseUnit,
    this.image,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final units = (json['saleUnits'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final base =
        units
            .where((unit) => unit['isInventoryBaseUnit'] == true)
            .firstOrNull ??
        units.firstOrNull;
    double? number(String key) => (json[key] as num?)?.toDouble();

    return ProductDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: category?['id'] as String?,
      categoryName: category?['name'] as String?,
      productType: json['productType'] as int,
      version: json['version'] as int,
      ivaRate: json['defaultTaxRate'] as int,
      iepsRate: json['defaultIepsTaxRate'] as int,
      iepsQuantityFactor: number('iepsQuantityFactor'),
      satUnitCode: json['satUnitCode'] as int,
      brandId: json['brandId'] as String?,
      brandName: json['brandName'] as String?,
      minimumStock: number('minimumStock'),
      maximumStock: number('maximumStock'),
      averageCost: number('averageCost'),
      stock: number('stock'),
      hasVariants: (json['variants'] as List<dynamic>? ?? const []).isNotEmpty,
      baseUnit: base == null ? null : ProductSaleUnitModel.fromJson(base),
      image: json['image'] == null
          ? null
          : ProductImageModel.fromJson(json['image'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final int productType;
  final int version;
  final int ivaRate;
  final int iepsRate;
  final double? iepsQuantityFactor;
  final int satUnitCode;
  final String? brandId;
  final String? brandName;
  final double? minimumStock;
  final double? maximumStock;
  final double? averageCost;
  final double? stock;
  final bool hasVariants;
  final ProductSaleUnitModel? baseUnit;
  final ProductImageModel? image;
}

class ProductSaleUnitModel {
  const ProductSaleUnitModel({
    required this.unitOfMeasure,
    required this.price,
    required this.cost,
    this.barcode,
  });

  factory ProductSaleUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductSaleUnitModel(
      unitOfMeasure: json['unitOfMeasure'] as int,
      price: (json['price'] as num).toDouble(),
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      barcode: json['barcode'] as String?,
    );
  }

  final int unitOfMeasure;
  final double price;
  final double cost;
  final String? barcode;
}
