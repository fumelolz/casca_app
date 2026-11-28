import 'package:casca_app/features/products/domain/inventory_movement_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('separa los motivos de entrada y de salida como web', () {
    expect(reasonsFor(MovementDirection.entry), [
      MovementReason.purchase,
      MovementReason.customerReturn,
    ]);
    expect(reasonsFor(MovementDirection.exit), [
      MovementReason.damage,
      MovementReason.loss,
    ]);
  });

  test('solo la compra lleva costo unitario', () {
    expect(
      toMovementRequest(
        reason: MovementReason.purchase,
        quantity: 5,
        unitCost: 12.5,
      ),
      {'type': 0, 'quantity': 5.0, 'unitCost': 12.5, 'reason': 0},
    );
    expect(
      toMovementRequest(reason: MovementReason.loss, quantity: 2, unitCost: 9),
      {'type': 1, 'quantity': 2.0, 'unitCost': null, 'reason': 4},
    );
  });

  test('calcula la existencia que quedará', () {
    expect(resultingStock(10, MovementDirection.entry, 3), 13);
    expect(resultingStock(10, MovementDirection.exit, 3), 7);
  });

  group('valida la cantidad', () {
    MovementQuantityError? validate(
      double? quantity, {
      MovementDirection direction = MovementDirection.exit,
      bool allowsDecimals = false,
    }) => validateMovementQuantity(
      quantity,
      direction: direction,
      currentStock: 4,
      allowsDecimals: allowsDecimals,
    );

    test('exige una cantidad positiva', () {
      expect(validate(null), MovementQuantityError.required);
      expect(validate(0), MovementQuantityError.notPositive);
    });

    test('rechaza decimales si el producto se vende por pieza', () {
      expect(validate(1.5), MovementQuantityError.decimals);
      expect(validate(1.5, allowsDecimals: true), isNull);
    });

    test('una salida no puede superar la existencia', () {
      expect(validate(5), MovementQuantityError.exceedsStock);
      expect(validate(4), isNull);
      expect(validate(5, direction: MovementDirection.entry), isNull);
    });
  });

  test('traduce los tipos y motivos del historial', () {
    expect(movementTypeLabel(1), 'Salida');
    expect(movementTypeLabel(9), 'Movimiento');
    expect(movementReasonLabel(5), 'Venta');
    expect(movementReasonLabel(7), 'Diferencia de conteo');
    expect(movementReasonLabel(null), '—');
  });
}
