import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/features/products/data/models/product_variant_model.dart';

class ProductDetailModel {
  const ProductDetailModel({
    required this.id,
    required this.name,
    this.sku = '',
    required this.productType,
    required this.version,
    required this.ivaRate,
    required this.iepsRate,
    required this.satUnitCode,
    this.variants = const [],
    this.saleUnits = const [],
    this.isActive = true,
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
      sku: json['sku'] as String? ?? '',
      description: json['description'] as String?,
      categoryId: category?['id'] as String?,
      categoryName: category?['name'] as String?,
      productType: json['productType'] as int,
      version: json['version'] as int,
      isActive: json['isActive'] as bool? ?? true,
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
      variants: (json['variants'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ProductVariantModel.fromJson)
          .toList(),
      saleUnits: units.map(ProductSaleUnitModel.fromJson).toList(),
      baseUnit: base == null ? null : ProductSaleUnitModel.fromJson(base),
      image: json['image'] == null
          ? null
          : ProductImageModel.fromJson(json['image'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String name;
  final String sku;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final int productType;
  final int version;
  final bool isActive;
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
  final List<ProductVariantModel> variants;
  final List<ProductSaleUnitModel> saleUnits;
  final ProductSaleUnitModel? baseUnit;
  final ProductImageModel? image;

  bool get hasVariants => variants.isNotEmpty;

  bool get isService => productType == ProductListItemModel.serviceType;
}

class ProductSaleUnitModel {
  const ProductSaleUnitModel({
    required this.unitOfMeasure,
    required this.price,
    required this.cost,
    this.barcode,
    this.isInventoryBaseUnit = false,
    this.allowsDecimalQuantity = false,
  });

  factory ProductSaleUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductSaleUnitModel(
      unitOfMeasure: json['unitOfMeasure'] as int,
      price: (json['price'] as num).toDouble(),
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      barcode: json['barcode'] as String?,
      isInventoryBaseUnit: json['isInventoryBaseUnit'] as bool? ?? false,
      allowsDecimalQuantity: json['allowsDecimalQuantity'] as bool? ?? false,
    );
  }

  final int unitOfMeasure;
  final double price;
  final double cost;
  final String? barcode;
  final bool isInventoryBaseUnit;
  final bool allowsDecimalQuantity;
}
