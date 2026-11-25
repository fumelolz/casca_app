import 'package:casca_app/features/products/domain/product_variant_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = VariantOption(name: 'Talla', values: ['CH', 'M']);
const _color = VariantOption(name: 'Color', values: ['Rojo', 'Azul']);

void main() {
  test('genera todas las combinaciones en orden', () {
    final variants = generateVariants([_size, _color], const []);

    expect(variants.map((v) => v.label), [
      'CH / Rojo',
      'CH / Azul',
      'M / Rojo',
      'M / Azul',
    ]);
  });

  test('al regenerar conserva los importes y actualiza el nombre', () {
    final first = generateVariants([_size], const []);
    final priced = [first.first.copyWith(price: 10), first.last];

    final variants = generateVariants([
      const VariantOption(name: 'Tamaño', values: ['CH', 'M', 'G']),
    ], priced);

    expect(variants.map((v) => v.price), [10, 0, 0]);
    expect(variants.first.choices.single.name, 'Tamaño');
  });

  test('sin opciones no hay variantes', () {
    expect(generateVariants(const [], const []), isEmpty);
  });

  test('agrupa por la opción elegida', () {
    final variants = generateVariants([_size, _color], const []);

    final groups = groupVariants(variants, 'Color');

    expect(groups.map((g) => g.title), ['Rojo', 'Azul']);
    expect(variantTitleWithin(groups.first.variants.last, 'Color'), 'M');
  });

  test('resume un rango de importes', () {
    expect(AmountSummary.of([5, 5]).text, '5');
    expect(AmountSummary.of([12, 5.5]).text, '5.5 - 12');
  });

  test('valida el nombre y los valores de una opción', () {
    String? check(String name, List<String> values) => validateVariantOption(
      VariantOption(name: name, values: values),
      [_size],
    );

    expect(check('', ['a']), 'Ingresa el nombre de la opción');
    expect(check('talla', ['a']), 'Ya existe una opción con ese nombre');
    expect(check('Color', []), 'Agrega al menos un valor');
    expect(check('Color', ['Rojo', 'rojo']), 'Hay valores repetidos');
    expect(check('Color', ['Rojo']), isNull);
  });

  test('pide el costo de las variantes con existencia', () {
    final variants = generateVariants([
      const VariantOption(name: 'Talla', values: ['1', '2', '3', '4']),
    ], const []).map((v) => v.copyWith(stock: 1)).toList();

    expect(
      missingVariantCostMessage(variants),
      'Indica el costo de las variantes con existencia inicial: 1, 2, 3 y 1 más.',
    );
    expect(
      missingVariantCostMessage([
        for (final v in variants) v.copyWith(cost: 2),
      ]),
      isNull,
    );
  });
}
