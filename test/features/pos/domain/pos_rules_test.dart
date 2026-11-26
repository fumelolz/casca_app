import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/domain/cart_rules.dart';
import 'package:casca_app/features/pos/domain/payment_rules.dart';
import 'package:casca_app/features/pos/domain/sale_error_rules.dart';
import 'package:casca_app/features/pos/domain/sale_request.dart';
import 'package:casca_app/features/pos/domain/scan_rules.dart';
import 'package:flutter_test/flutter_test.dart';

PosCatalogItemModel _item({
  String id = 'i1',
  double price = 10,
  double stock = 5,
  double factor = 1,
  bool decimals = false,
  bool inventory = true,
  String saleUnit = 'u1',
}) {
  return PosCatalogItemModel(
    id: id,
    productId: 'p1',
    sellableItemId: saleUnit,
    type: 0,
    displayName: 'Arroz',
    price: price,
    sku: 'A1',
    quantity: stock,
    conversionFactor: factor,
    allowsDecimalQuantity: decimals,
    affectsInventory: inventory,
  );
}

void main() {
  group('carrito', () {
    test('un producto sin existencias no está disponible', () {
      expect(isAvailable(_item(stock: 0)), isFalse);
      expect(isAvailable(_item(stock: 0, inventory: false)), isTrue);
    });

    test('solo acepta decimales si el producto lo permite', () {
      expect(isValidQuantity(_item(), 1.5), isFalse);
      expect(isValidQuantity(_item(decimals: true), 1.5), isTrue);
      expect(isValidQuantity(_item(), 0), isFalse);
    });

    test('las presentaciones comparten las existencias', () {
      final box = _item(stock: 25, factor: 12, saleUnit: 'box');
      final piece = _item(stock: 25);
      final lines = [CartLine(item: box, quantity: 2)];

      expect(maxQuantity(lines, piece, 'otra'), 1);
    });

    test('suma los importes sin errores de redondeo', () {
      final preview = untaxedPreview([
        CartLine(item: _item(price: 0.1), quantity: 1),
        CartLine(item: _item(price: 0.2, saleUnit: 'u2'), quantity: 1),
      ]);

      expect(preview.finalTotal, 0.3);
    });

    test('con una lista de precios el total lo calcula el servidor', () {
      final lines = [CartLine(item: _item(), quantity: 1)];
      final priced = lines.single.withPricing(
        const LinePricing(priceListId: 'l1'),
      );

      expect(canTotalLocally(lines, null), isTrue);
      expect(canTotalLocally(lines, 'l1'), isFalse);
      expect(canTotalLocally([priced], null), isFalse);
    });

    test('calcula la cantidad a partir del importe', () {
      expect(quantityForAmount(10, 30), 0.333);
      expect(quantityForAmount(10, 0), isNull);
    });
  });

  test('corrige el separador de un SKU mal leído por el lector', () {
    expect(normalizeScannedCode(" prd'1a2b3c "), 'PRD-1A2B3C');
    expect(normalizeScannedCode('7501234567890'), '7501234567890');
  });

  group('cobro', () {
    test('convierte el texto en centavos', () {
      expect(parseMoneyToCents('12'), 1200);
      expect(parseMoneyToCents('12.5'), 1250);
      expect(parseMoneyToCents(''), isNull);
      expect(sanitizeMoneyText(r'$00.129'), '0.12');
    });

    test('propone el exacto, el billete siguiente y su doble', () {
      expect(quickCashAmounts(8550), [8550, 10000, 20000]);
      expect(quickCashAmounts(150000), [150000, 200000, 400000]);
    });

    test('en efectivo calcula el cambio y exige cubrir el total', () {
      expect(cashPayment(8550, '50'), isNull);

      final payment = cashPayment(8550, '100')!;
      expect(payment.changeCents, 1450);
      expect(payment.lines.single.amountCents, 8550);
      expect(payment.lines.single.receivedCents, 10000);
    });

    test('en pago dividido el cambio solo sale del efectivo', () {
      final split = evaluateSplit(10000, {
        PaymentMethod.cash: '80',
        PaymentMethod.debitCard: '40',
      });

      expect(split.changeCents, 2000);
      expect(split.payment!.lines.first.amountCents, 6000);
      expect(split.payment!.lines.last.amountCents, 4000);
    });

    test('no cobra si falta dinero o la tarjeta supera el total', () {
      final short = evaluateSplit(10000, {PaymentMethod.cash: '50'});
      final over = evaluateSplit(10000, {PaymentMethod.transfer: '120'});

      expect(short.shortfallCents, 5000);
      expect(short.payment, isNull);
      expect(over.exceedsTotal, isTrue);
      expect(over.payment, isNull);
    });

    test('arma la venta con los códigos de pago del servidor', () {
      final request = saleRequest([
        CartLine(item: _item(), quantity: 2),
      ], singlePayment(PaymentMethod.creditCard, 2000));

      expect(request['payments'], [
        {'method': 4, 'amount': 20},
      ]);
      expect((request['items'] as List).single, containsPair('quantity', 2));
    });

    test('genera claves distintas y con el formato del servidor', () {
      final key = newIdempotencyKey();

      expect(key, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(newIdempotencyKey(), isNot(key));
    });

    test('ubica el error del servidor en su renglón', () {
      final lines = [CartLine(item: _item(), quantity: 1)];
      final failure = saleFailure(
        const ApiException(
          type: ApiErrorType.client,
          details: [
            ApiErrorDetail(description: 'Sin existencias.', field: 'items[0]'),
          ],
        ),
        lines,
      );

      expect(failure.lineErrors, {lines.single.key: 'Sin existencias.'});
    });

    test('sin respuesta avisa que la venta quedó sin confirmar', () {
      final failure = saleFailure(
        const ApiException(type: ApiErrorType.network),
        const [],
      );

      expect(failure.message, unconfirmedSaleError);
    });
  });
}
