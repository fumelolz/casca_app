class PosPriceListModel {
  const PosPriceListModel({required this.id, required this.name});

  factory PosPriceListModel.fromJson(Map<String, dynamic> json) {
    return PosPriceListModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
}
