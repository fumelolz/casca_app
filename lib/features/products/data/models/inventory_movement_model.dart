class InventoryMovementModel {
  const InventoryMovementModel({
    required this.displayName,
    required this.movementType,
    required this.quantity,
    required this.unitCost,
    required this.totalCost,
    required this.createdAt,
    this.reason,
  });

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    return InventoryMovementModel(
      displayName: json['displayName'] as String? ?? '',
      movementType: json['movementType'] as int,
      quantity: (json['quantity'] as num).toDouble(),
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
      reason: json['reason'] as int?,
      createdAt: DateTime.parse(json['createdOnUtc'] as String),
    );
  }

  final String displayName;
  final int movementType;
  final double quantity;
  final double unitCost;
  final double totalCost;
  final int? reason;
  final DateTime createdAt;
}
