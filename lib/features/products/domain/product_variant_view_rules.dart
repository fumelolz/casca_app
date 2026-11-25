import 'package:casca_app/features/products/data/models/product_variant_model.dart';

const int activeVariantStatus = 1;
const int historicalVariantStatus = 3;

class VariantOptionGroup {
  const VariantOptionGroup({required this.name, required this.values});

  final String name;
  final List<String> values;
}

class OptionSelection {
  const OptionSelection({
    required this.name,
    required this.value,
    this.createdNow = false,
  });

  final String name;
  final String value;
  final bool createdNow;
}

class VariantRowGroup {
  const VariantRowGroup({required this.title, required this.variants});

  final String title;
  final List<ProductVariantModel> variants;

  Set<String> get ids => {for (final variant in variants) variant.id};

  int get activeCount => variants.where(isVariantActive).length;

  double get totalStock =>
      variants.fold(0, (total, variant) => total + variant.stock);

  List<double> get prices =>
      [for (final variant in variants) ?variant.saleUnit?.price]..sort();
}

bool isVariantActive(ProductVariantModel variant) =>
    variant.status == activeVariantStatus;

String variantStatusLabel(int status) {
  return switch (status) {
    activeVariantStatus => 'Activa',
    historicalVariantStatus => 'Histórica',
    _ => 'Inactiva',
  };
}

bool _sameText(String first, String second) =>
    first.trim().toLowerCase() == second.trim().toLowerCase();

List<ProductVariantOptionModel> sortedOptions(ProductVariantModel variant) {
  return [...variant.options]
    ..sort((a, b) => a.optionPosition.compareTo(b.optionPosition));
}

String variantName(ProductVariantModel variant) {
  if (variant.displayName.isNotEmpty) return variant.displayName;
  return sortedOptions(variant).map((option) => option.value).join(' / ');
}

List<VariantOptionGroup> buildOptionGroups(List<ProductVariantModel> variants) {
  final names = <String>[];
  final positions = <int>[];
  final values = <List<ProductVariantOptionModel>>[];

  for (final variant in variants) {
    for (final option in variant.options) {
      var index = names.indexWhere((name) => _sameText(name, option.name));
      if (index < 0) {
        index = names.length;
        names.add(option.name);
        positions.add(option.optionPosition);
        values.add([]);
      }
      if (!values[index].any((v) => _sameText(v.value, option.value))) {
        values[index].add(option);
      }
    }
  }

  final order = List.generate(names.length, (index) => index)
    ..sort((a, b) => positions[a].compareTo(positions[b]));
  return [
    for (final index in order)
      VariantOptionGroup(
        name: names[index],
        values: [
          for (final option in [
            ...values[index],
          ]..sort((a, b) => a.valuePosition.compareTo(b.valuePosition)))
            option.value,
        ],
      ),
  ];
}

List<ProductVariantModel> sortVariants(List<ProductVariantModel> variants) {
  final groups = buildOptionGroups(variants);

  List<int> rank(ProductVariantModel variant) {
    return [
      for (final group in groups)
        group.values.indexWhere(
          (value) => variant.options.any(
            (option) =>
                _sameText(option.name, group.name) &&
                _sameText(option.value, value),
          ),
        ),
    ];
  }

  final ranked = [
    for (final (index, variant) in variants.indexed)
      (variant: variant, rank: rank(variant), index: index),
  ];
  ranked.sort((a, b) {
    for (var i = 0; i < a.rank.length; i++) {
      final difference = a.rank[i].compareTo(b.rank[i]);
      if (difference != 0) return difference;
    }
    return a.index.compareTo(b.index);
  });
  return [for (final item in ranked) item.variant];
}

List<VariantRowGroup> buildRowGroups(
  List<ProductVariantModel> variants,
  String groupBy,
) {
  final groups = <String, List<ProductVariantModel>>{};
  for (final variant in variants) {
    final value =
        variant.options
            .where((option) => option.name == groupBy)
            .firstOrNull
            ?.value ??
        'Sin $groupBy';
    groups.putIfAbsent(value, () => []).add(variant);
  }
  return [
    for (final entry in groups.entries)
      VariantRowGroup(title: entry.key, variants: entry.value),
  ];
}

String variantRowTitle(ProductVariantModel variant, String groupBy) {
  final options = sortedOptions(variant);
  final remaining = options.where((option) => option.name != groupBy).toList();
  final source = remaining.isEmpty ? options : remaining;
  final title = source.map((option) => option.value).join(' / ');
  return title.isEmpty ? variantName(variant) : title;
}

ProductVariantModel? findVariantByOptions(
  List<ProductVariantModel> variants,
  List<OptionSelection> selection,
) {
  return variants
      .where(
        (variant) =>
            variant.options.length == selection.length &&
            selection.every(
              (chosen) => variant.options.any(
                (option) =>
                    _sameText(option.name, chosen.name) &&
                    _sameText(option.value, chosen.value),
              ),
            ),
      )
      .firstOrNull;
}

List<List<OptionSelection>> buildExtraCombinations(
  List<ProductVariantModel> variants,
  List<OptionSelection> selection,
) {
  final groups = buildOptionGroups(variants);
  if (groups.isEmpty ||
      groups.length != selection.length ||
      selection.any((choice) => choice.value.isEmpty)) {
    return const [];
  }

  bool isNewValue(int index) =>
      selection[index].createdNow &&
      !groups[index].values.any(
        (value) => _sameText(value, selection[index].value),
      );

  if (!List.generate(groups.length, isNewValue).contains(true)) {
    return const [];
  }

  var combinations = <List<OptionSelection>>[[]];
  for (final (index, group) in groups.indexed) {
    final values = isNewValue(index) ? [selection[index].value] : group.values;
    combinations = [
      for (final combination in combinations)
        for (final value in values)
          [...combination, OptionSelection(name: group.name, value: value)],
    ];
  }

  return [
    for (final combination in combinations)
      if (!List.generate(
            combination.length,
            (i) => _sameText(combination[i].value, selection[i].value),
          ).every((same) => same) &&
          findVariantByOptions(variants, combination) == null)
        combination,
  ];
}

Map<String, dynamic> toNewVariant(
  List<OptionSelection> selection, {
  required int unitOfMeasure,
  required bool allowsDecimals,
  required double price,
  String? barcode,
}) {
  return {
    'displayName': selection.map((option) => option.value).join(' / '),
    'options': [
      for (final option in selection)
        {'name': option.name, 'value': option.value},
    ],
    'saleUnits': [
      {
        'unitOfMeasure': unitOfMeasure,
        'barcode': barcode,
        'conversionFactor': 1,
        'price': price,
        'affectsInventory': true,
        'allowsDecimalQuantity': allowsDecimals,
        'isInventoryBaseUnit': true,
      },
    ],
  };
}
