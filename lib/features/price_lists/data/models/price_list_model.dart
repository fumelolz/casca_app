class PriceListModel {
  const PriceListModel({
    required this.id,
    required this.name,
    required this.priceCount,
  });

  factory PriceListModel.fromJson(Map<String, dynamic> json) {
    return PriceListModel(
      id: json['id'] as String,
      name: json['name'] as String,
      priceCount: json['priceCount'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final int priceCount;
}

class PriceListItemModel {
  const PriceListItemModel({
    required this.sellableItemId,
    required this.displayName,
    required this.sku,
    required this.price,
  });

  factory PriceListItemModel.fromJson(Map<String, dynamic> json) {
    return PriceListItemModel(
      sellableItemId: json['sellableItemId'] as String,
      displayName: json['displayName'] as String,
      sku: json['sku'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
    );
  }

  final String sellableItemId;
  final String displayName;
  final String sku;
  final double price;
}
