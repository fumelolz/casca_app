class StoreListItemModel {
  const StoreListItemModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.phone,
    this.email,
  });

  factory StoreListItemModel.fromJson(Map<String, dynamic> json) {
    return StoreListItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  final String id;
  final String name;
  final bool isActive;
  final String? phone;
  final String? email;
}
