class CashRegisterModel {
  const CashRegisterModel({
    required this.id,
    required this.name,
    required this.isOpen,
    this.description,
  });

  factory CashRegisterModel.fromJson(Map<String, dynamic> json) {
    return CashRegisterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isOpen: json['isOpen'] as bool,
      description: json['description'] as String?,
    );
  }

  final String id;
  final String name;
  final bool isOpen;
  final String? description;
}

class CashRegisterRequest {
  const CashRegisterRequest({required this.name, this.description});

  final String name;
  final String? description;

  Map<String, dynamic> toJson() => {'name': name, 'description': description};
}
