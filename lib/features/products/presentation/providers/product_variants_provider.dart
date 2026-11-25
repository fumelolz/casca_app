import 'package:casca_app/features/products/domain/product_variant_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int newOptionIndex = -1;

class ProductVariantsState {
  const ProductVariantsState({
    this.options = const [],
    this.variants = const [],
    this.editing,
    this.selectedGroup,
  });

  final List<VariantOption> options;
  final List<ProductVariantDraft> variants;
  final int? editing;
  final String? selectedGroup;

  bool get isEditing => editing != null;

  bool get hasChanges => options.isNotEmpty || isEditing;

  String? get groupBy {
    if (options.isEmpty) return null;
    final names = options.map((option) => option.name);
    return names.contains(selectedGroup) ? selectedGroup : options.first.name;
  }

  ProductVariantsState copyWith({
    List<VariantOption>? options,
    List<ProductVariantDraft>? variants,
    int? Function()? editing,
    String? selectedGroup,
  }) {
    return ProductVariantsState(
      options: options ?? this.options,
      variants: variants ?? this.variants,
      editing: editing == null ? this.editing : editing(),
      selectedGroup: selectedGroup ?? this.selectedGroup,
    );
  }
}

class ProductVariantsController extends Notifier<ProductVariantsState> {
  @override
  ProductVariantsState build() => const ProductVariantsState();

  void edit(int index) => state = state.copyWith(editing: () => index);

  void closeEditor() => state = state.copyWith(editing: () => null);

  void groupBy(String name) => state = state.copyWith(selectedGroup: name);

  void saveOption(VariantOption option) {
    final index = state.editing;
    if (index == null) return;

    final options = [...state.options];
    if (index == newOptionIndex) {
      options.add(option);
    } else {
      options[index] = option;
    }
    _apply(options);
  }

  void removeEditingOption() {
    final index = state.editing;
    if (index == null || index == newOptionIndex) return closeEditor();
    _apply([...state.options]..removeAt(index));
  }

  void setPrice(Set<String> keys, double price) {
    _update(keys, (variant) => variant.copyWith(price: price));
  }

  void setCost(Set<String> keys, double cost) {
    _update(keys, (variant) => variant.copyWith(cost: cost));
  }

  void setStock(Set<String> keys, double stock) {
    _update(keys, (variant) => variant.copyWith(stock: stock));
  }

  void _apply(List<VariantOption> options) {
    state = state.copyWith(
      options: options,
      variants: generateVariants(options, state.variants),
      editing: () => null,
    );
  }

  void _update(
    Set<String> keys,
    ProductVariantDraft Function(ProductVariantDraft) change,
  ) {
    state = state.copyWith(
      variants: [
        for (final variant in state.variants)
          keys.contains(variant.key) ? change(variant) : variant,
      ],
    );
  }
}

final productVariantsProvider =
    NotifierProvider.autoDispose<
      ProductVariantsController,
      ProductVariantsState
    >(ProductVariantsController.new);
