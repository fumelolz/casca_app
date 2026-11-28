import 'package:casca_app/features/products/data/models/inventory_movement_model.dart';
import 'package:casca_app/features/products/domain/product_detail_rules.dart';
import 'package:flutter_test/flutter_test.dart';

InventoryMovementModel _movement(double quantity) => InventoryMovementModel(
  displayName: 'Arroz',
  movementType: quantity > 0 ? 0 : 1,
  quantity: quantity,
  unitCost: 0,
  totalCost: 0,
  createdAt: DateTime(2026),
);

void main() {
  test('reconstruye la existencia después de cada movimiento', () {
    expect(
      stockAfterEachMovement([_movement(-1), _movement(-2), _movement(100)], 97),
      [97, 98, 100],
    );
  });

  test('deja solo el nombre de la variante', () {
    expect(movementSubject('Pulsera plata 21 cm', 'Pulsera plata'), '21 cm');
    expect(movementSubject('Pulsera plata', 'Pulsera plata'), 'Pulsera plata');
    expect(movementSubject('Otro nombre', 'Pulsera plata'), 'Otro nombre');
  });

  test('traduce la tasa de IVA', () {
    expect(ivaLabel(0), 'IVA 16%');
    expect(ivaLabel(99), isNull);
  });
}
