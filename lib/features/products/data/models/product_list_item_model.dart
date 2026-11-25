class ProductImageModel {
  const ProductImageModel({required this.paths, this.fullSizePaths = const []});

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    List<String> pick(List<String> keys) {
      return keys
          .map((key) => json[key])
          .whereType<String>()
          .where((path) => path.isNotEmpty)
          .toSet()
          .toList();
    }

    const thumbnails = ['webpThumbnailUrl', 'thumbnailUrl'];
    const originals = ['webpUrl', 'originalUrl'];
    return ProductImageModel(
      paths: pick([...thumbnails, ...originals]),
      fullSizePaths: pick([...originals, ...thumbnails]),
    );
  }

  final List<String> paths;
  final List<String> fullSizePaths;
}

class ProductListItemModel {
  const ProductListItemModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.minimumStock,
    required this.averageCost,
    required this.productType,
    required this.hasVariants,
    required this.variantCount,
    this.maximumStock,
    this.maxPrice,
    this.image,
  });

  factory ProductListItemModel.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;

    return ProductListItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toDouble(),
      minimumStock: (json['minimumStock'] as num).toDouble(),
      maximumStock: (json['maximumStock'] as num?)?.toDouble(),
      averageCost: (json['averageCost'] as num).toDouble(),
      productType: json['productType'] as int? ?? 0,
      hasVariants: json['hasVariants'] as bool? ?? false,
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      variantCount: json['variantCount'] as int? ?? 0,
      image: image == null ? null : ProductImageModel.fromJson(image),
    );
  }

  static const int serviceType = 1;

  final String id;
  final String name;
  final String sku;
  final double price;
  final double stock;
  final double minimumStock;
  final double? maximumStock;
  final double averageCost;
  final int productType;
  final bool hasVariants;
  final double? maxPrice;
  final int variantCount;
  final ProductImageModel? image;

  bool get isService => productType == serviceType;
}
