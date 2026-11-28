enum MovementDirection { entry, exit }

enum MovementReason {
  purchase(0, 'Compra', MovementDirection.entry),
  customerReturn(1, 'Devolución', MovementDirection.entry),
  damage(3, 'Merma', MovementDirection.exit),
  loss(4, 'Pérdida', MovementDirection.exit);

  const MovementReason(this.code, this.label, this.direction);

  final int code;
  final String label;
  final MovementDirection direction;
}

enum MovementQuantityError { required, notPositive, decimals, exceedsStock }

const _movementTypeLabels = {0: 'Entrada', 1: 'Salida', 2: 'Ajuste', 3: 'Conteo'};

const _historyReasonLabels = {
  0: 'Compra',
  1: 'Devolución',
  2: 'Transferencia entrante',
  3: 'Merma',
  4: 'Pérdida',
  5: 'Venta',
  6: 'Transferencia saliente',
  7: 'Diferencia de conteo',
  8: 'Inicialización',
};

List<MovementReason> reasonsFor(MovementDirection direction) => [
  for (final reason in MovementReason.values)
    if (reason.direction == direction) reason,
];

bool requiresUnitCost(MovementReason reason) =>
    reason == MovementReason.purchase;

double resultingStock(
  double currentStock,
  MovementDirection direction,
  double quantity,
) {
  return direction == MovementDirection.entry
      ? currentStock + quantity
      : currentStock - quantity;
}

MovementQuantityError? validateMovementQuantity(
  double? quantity, {
  required MovementDirection direction,
  required double currentStock,
  required bool allowsDecimals,
}) {
  if (quantity == null) return MovementQuantityError.required;
  if (quantity <= 0) return MovementQuantityError.notPositive;
  if (!allowsDecimals && quantity != quantity.truncateToDouble()) {
    return MovementQuantityError.decimals;
  }
  if (direction == MovementDirection.exit && quantity > currentStock) {
    return MovementQuantityError.exceedsStock;
  }
  return null;
}

Map<String, dynamic> toMovementRequest({
  required MovementReason reason,
  required double quantity,
  double? unitCost,
}) {
  return {
    'type': reason.direction.index,
    'quantity': quantity,
    'unitCost': requiresUnitCost(reason) ? unitCost : null,
    'reason': reason.code,
  };
}

String movementTypeLabel(int type) => _movementTypeLabels[type] ?? 'Movimiento';

String movementReasonLabel(int? reason) =>
    reason == null ? '—' : _historyReasonLabels[reason] ?? '—';
