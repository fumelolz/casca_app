import 'package:casca_app/shared/formatters/number_formatters.dart';

const int maxVariantOptions = 3;
const int maxOptionNameLength = 50;
const int maxOptionValueLength = 30;
const int _listedMissingCosts = 3;
const int _activeStatus = 1;

class VariantOption {
  const VariantOption({required this.name, required this.values});

  final String name;
  final List<String> values;
}

class VariantChoice {
  const VariantChoice({required this.name, required this.value});

  final String name;
  final String value;
}

class ProductVariantDraft {
  const ProductVariantDraft({
    required this.choices,
    this.price = 0,
    this.cost = 0,
    this.stock = 0,
  });

  final List<VariantChoice> choices;
  final double price;
  final double cost;
  final double stock;

  String get key => choices.map((choice) => choice.value).join('|');

  String get label => choices.map((choice) => choice.value).join(' / ');

  ProductVariantDraft copyWith({
    List<VariantChoice>? choices,
    double? price,
    double? cost,
    double? stock,
  }) {
    return ProductVariantDraft(
      choices: choices ?? this.choices,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
    );
  }
}

class VariantGroup {
  const VariantGroup({required this.title, required this.variants});

  final String title;
  final List<ProductVariantDraft> variants;

  Set<String> get keys => {for (final variant in variants) variant.key};
}

class AmountSummary {
  const AmountSummary({required this.min, required this.max});

  factory AmountSummary.of(Iterable<double> amounts) {
    final sorted = amounts.toList()..sort();
    if (sorted.isEmpty) return const AmountSummary(min: 0, max: 0);
    return AmountSummary(min: sorted.first, max: sorted.last);
  }

  final double min;
  final double max;

  bool get isMixed => min != max;

  String get text {
    if (!isMixed) return formatQuantity(min);
    return '${formatQuantity(min)} - ${formatQuantity(max)}';
  }
}

List<ProductVariantDraft> generateVariants(
  List<VariantOption> options,
  List<ProductVariantDraft> existing,
) {
  if (options.isEmpty) return const [];

  var combinations = <List<VariantChoice>>[[]];
  for (final option in options) {
    combinations = [
      for (final combination in combinations)
        for (final value in option.values)
          [...combination, VariantChoice(name: option.name, value: value)],
    ];
  }

  final previous = {for (final variant in existing) variant.key: variant};
  return [
    for (final choices in combinations)
      _keepAmounts(ProductVariantDraft(choices: choices), previous),
  ];
}

ProductVariantDraft _keepAmounts(
  ProductVariantDraft generated,
  Map<String, ProductVariantDraft> previous,
) {
  final match = previous[generated.key];
  return match == null ? generated : match.copyWith(choices: generated.choices);
}

List<VariantGroup> groupVariants(
  List<ProductVariantDraft> variants,
  String groupBy,
) {
  final groups = <String, List<ProductVariantDraft>>{};
  for (final variant in variants) {
    for (final choice in variant.choices) {
      if (choice.name != groupBy) continue;
      groups.putIfAbsent(choice.value, () => []).add(variant);
    }
  }
  return [
    for (final entry in groups.entries)
      VariantGroup(title: entry.key, variants: entry.value),
  ];
}

String variantTitleWithin(ProductVariantDraft variant, String groupBy) {
  final visible = variant.choices
      .where((choice) => choice.name != groupBy)
      .map((choice) => choice.value);
  return visible.isEmpty ? variant.label : visible.join(' / ');
}

String? validateVariantOption(
  VariantOption option,
  Iterable<VariantOption> others,
) {
  final name = option.name.trim().toLowerCase();
  if (name.isEmpty) return 'Ingresa el nombre de la opción';
  if (others.any((other) => other.name.trim().toLowerCase() == name)) {
    return 'Ya existe una opción con ese nombre';
  }
  if (option.values.isEmpty) return 'Agrega al menos un valor';
  final unique = {for (final value in option.values) value.toLowerCase()};
  if (unique.length != option.values.length) return 'Hay valores repetidos';
  return null;
}

String? missingVariantCostMessage(List<ProductVariantDraft> variants) {
  final missing = variants
      .where((variant) => variant.stock > 0 && variant.cost <= 0)
      .toList();
  if (missing.isEmpty) return null;

  final labels = missing
      .take(_listedMissingCosts)
      .map((variant) => variant.label)
      .join(', ');
  final others = missing.length - _listedMissingCosts;
  final rest = others > 0 ? ' y $others más' : '';
  return 'Indica el costo de las variantes con existencia inicial: $labels$rest.';
}

Map<String, dynamic> toVariantRequest(ProductVariantDraft variant) {
  return {
    'displayName': variant.label,
    'status': _activeStatus,
    'minimumStock': 0,
    'initialStock': variant.stock,
    'unitCost': variant.cost,
    'options': [
      for (final choice in variant.choices)
        {'name': choice.name, 'value': choice.value},
    ],
    'saleUnits': [
      {
        'unitOfMeasure': 0,
        'conversionFactor': 1,
        'price': variant.price,
        'affectsInventory': true,
        'allowsDecimalQuantity': false,
        'isInventoryBaseUnit': true,
        'barcode': null,
      },
    ],
  };
}
