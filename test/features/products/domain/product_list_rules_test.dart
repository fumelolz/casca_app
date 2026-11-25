import 'package:casca_app/features/products/domain/product_list_rules.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profitMargin', () {
    test('calcula la ganancia sobre el precio de venta', () {
      final margin = profitMargin(18, 15)!;

      expect(margin.amount, 3);
      expect(margin.percentage, 17);
      expect(margin.tone, ProfitTone.positive);
    });

    test('marca la pérdida como negativa', () {
      expect(profitMargin(10, 12)!.tone, ProfitTone.negative);
    });

    test('sin costo no calcula, salvo que el costo cero sea válido', () {
      expect(profitMargin(10, 0), isNull);
      expect(profitMargin(10, 0, allowZeroCost: true)!.percentage, 100);
    });

    test('con precio cero no calcula porcentaje', () {
      expect(profitMargin(0, 5)!.percentage, isNull);
    });
  });

  group('stockLevel', () {
    test('sin existencias es sin stock', () {
      expect(stockLevel(0, 5, 100).status, StockStatus.out);
      expect(stockLevel(0, 0, null).percentage, isNull);
    });

    test('el mínimo tiene prioridad sobre el porcentaje', () {
      expect(stockLevel(10, 10, 12).status, StockStatus.critical);
    });

    test('clasifica por porcentaje del máximo', () {
      expect(stockLevel(80, 5, 100).status, StockStatus.optimal);
      expect(stockLevel(75, 5, 100).status, StockStatus.moderate);
      expect(stockLevel(50, 5, 100).status, StockStatus.moderate);
      expect(stockLevel(49, 5, 100).status, StockStatus.low);
    });

    test('limita el porcentaje a 100', () {
      expect(stockLevel(250, 5, 100).percentage, 100);
    });

    test('sin máximo o con máximo cero no hay porcentaje', () {
      expect(stockLevel(20, 5, null).status, StockStatus.ok);
      expect(stockLevel(3, 0, 0).percentage, isNull);
    });
  });

  group('formatos', () {
    test('dinero con miles y dos decimales', () {
      expect(formatMoney(0), r'$0.00');
      expect(formatMoney(1234567.5), r'$1,234,567.50');
      expect(formatMoney(-3), r'-$3.00');
    });

    test('cantidades sin ceros sobrantes y hasta tres decimales', () {
      expect(formatQuantity(12), '12');
      expect(formatQuantity(1500), '1,500');
      expect(formatQuantity(7.5), '7.5');
      expect(formatQuantity(0.1255), '0.126');
    });
  });
}
