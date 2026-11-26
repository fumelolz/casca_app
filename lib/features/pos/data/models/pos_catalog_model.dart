class PosCatalogItemModel {
  const PosCatalogItemModel({
    required this.id,
    required this.productId,
    required this.sellableItemId,
    required this.type,
    required this.displayName,
    required this.price,
    required this.sku,
    required this.quantity,
    required this.conversionFactor,
    required this.allowsDecimalQuantity,
    required this.affectsInventory,
    this.productVariantId,
    this.imagePaths = const [],
    this.thumbnailPaths = const [],
    this.fromPriceList = false,
  });

  factory PosCatalogItemModel.fromJson(
    Map<String, dynamic> json, {
    bool fromPriceList = false,
  }) {
    final image = json['image'] as Map<String, dynamic>?;
    List<String> paths(List<String> keys) => [
      for (final key in keys)
        if (image?[key] case final String path when path.isNotEmpty) path,
    ];

    return PosCatalogItemModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productVariantId: json['productVariantId'] as String?,
      sellableItemId: json['sellableItemId'] as String,
      type: json['type'] as int,
      displayName: json['displayName'] as String,
      price: (json['price'] as num).toDouble(),
      sku: json['sku'] as String? ?? '',
      quantity: (json['quantity'] as num).toDouble(),
      conversionFactor: (json['conversionFactor'] as num).toDouble(),
      allowsDecimalQuantity: json['allowsDecimalQuantity'] as bool,
      affectsInventory: json['affectsInventory'] as bool,
      imagePaths: paths(['webpMediumUrl', 'webpUrl', 'originalUrl']),
      thumbnailPaths: paths(['webpThumbnailUrl', 'thumbnailUrl', 'webpUrl']),
      fromPriceList: fromPriceList,
    );
  }

  final String id;
  final String productId;
  final String? productVariantId;
  final String sellableItemId;
  final int type;
  final String displayName;
  final double price;
  final String sku;
  final double quantity;
  final double conversionFactor;
  final bool allowsDecimalQuantity;
  final bool affectsInventory;
  final List<String> imagePaths;
  final List<String> thumbnailPaths;
  final bool fromPriceList;
}

class PosCatalogPageModel {
  const PosCatalogPageModel({required this.items, required this.hasNextPage});

  factory PosCatalogPageModel.fromJson(
    Map<String, dynamic> json, {
    bool fromPriceList = false,
  }) {
    return PosCatalogPageModel(
      items: [
        for (final item in json['items'] as List<Object?>)
          PosCatalogItemModel.fromJson(
            item as Map<String, dynamic>,
            fromPriceList: fromPriceList,
          ),
      ],
      hasNextPage: json['hasNextPage'] as bool,
    );
  }

  final List<PosCatalogItemModel> items;
  final bool hasNextPage;
}
