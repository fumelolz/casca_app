import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/data/models/product_variant_model.dart';
import 'package:casca_app/features/products/data/photo_picker.dart';
import 'package:casca_app/features/products/data/product_image_repository.dart';
import 'package:casca_app/features/products/data/product_variant_repository.dart';
import 'package:casca_app/features/products/domain/product_variant_view_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_form_provider.dart';
import 'package:casca_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VariantAction { status, prices, order, form }

class VariantEdit {
  const VariantEdit({
    required this.original,
    required this.displayName,
    required this.optionValues,
    required this.price,
    required this.barcode,
    required this.trackInventory,
    this.limits,
    this.photo,
  });

  final ProductVariantModel original;
  final String displayName;
  final Map<String, String> optionValues;
  final double price;
  final String? barcode;
  final bool trackInventory;
  final ({double minimum, double? maximum})? limits;
  final PickedPhoto? photo;
}

class VariantAddition {
  const VariantAddition({
    required this.selection,
    required this.variants,
    this.photo,
  });

  final List<OptionSelection> selection;
  final List<Map<String, dynamic>> variants;
  final PickedPhoto? photo;
}

class VariantActionController extends Notifier<AsyncValue<void>> {
  VariantActionController(this.key);

  final (String, VariantAction) key;

  String get _productId => key.$1;

  ProductVariantRepository get _variants =>
      ref.read(productVariantRepositoryProvider);

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> changeStatus(String variantId, {required bool active}) {
    return _run((product) {
      return _variants.changeStatus(_productId, variantId, {
        'isActive': active,
        'version': product.version,
      });
    });
  }

  Future<bool> changePrices(
    Set<String> variantIds, {
    double? price,
    double? percentage,
  }) {
    return _run((product) {
      return _variants.changePrices(_productId, {
        'variantIds': variantIds.toList(),
        'price': price,
        'percentage': percentage,
        'version': product.version,
      });
    });
  }

  Future<bool> reorder(List<VariantOptionGroup> groups) {
    return _run((product) {
      return _variants.reorderOptions(_productId, {
        'options': [
          for (final group in groups)
            {'name': group.name, 'values': group.values},
        ],
        'version': product.version,
      });
    });
  }

  Future<bool> add(VariantAddition addition) {
    return _run((product) async {
      var created = findVariantByOptions(product.variants, addition.selection);
      if (created == null) {
        await _variants.addVariants(_productId, {
          'version': product.version,
          'variants': addition.variants,
        });
      }

      final photo = addition.photo;
      if (photo == null) return;
      final updated = await _reload();
      created = findVariantByOptions(updated.variants, addition.selection);
      if (created == null) return;
      await ref
          .read(productImageRepositoryProvider)
          .uploadVariantImage(
            _productId,
            created.id,
            photo,
            altText: variantName(created),
          );
    });
  }

  Future<bool> edit(VariantEdit change) {
    return _run((product) => _applyEdit(product, change));
  }

  Future<void> _applyEdit(
    ProductDetailModel product,
    VariantEdit change,
  ) async {
    final original = change.original;
    final latest = product.variants.firstWhere(
      (variant) => variant.id == original.id,
    );
    var version = product.version;

    for (final option in original.options) {
      final value = change.optionValues[option.name]?.trim() ?? '';
      final current = latest.options
          .where((other) => other.name == option.name)
          .firstOrNull
          ?.value;
      if (value.isEmpty || value == option.value || value == current) continue;
      await _variants.renameOptionValue(_productId, {
        'optionName': option.name,
        'currentValue': current,
        'newValue': value,
        'version': version++,
      });
    }

    final name = change.displayName.trim();
    if (name != original.displayName && name != latest.displayName) {
      await _variants.updateVariant(_productId, original.id, {
        'displayName': name,
        'version': version++,
      });
    }

    final unit = latest.saleUnit;
    if (unit != null) {
      final enables = change.trackInventory && !unit.affectsInventory;
      final changed =
          change.price != unit.price ||
          change.barcode != _textOrNull(unit.barcode) ||
          enables;
      if (changed) {
        await _variants.updateSaleUnit(_productId, original.id, unit.id, {
          'displayName': unit.displayName,
          'unitOfMeasure': unit.unitOfMeasure,
          'barcode': change.barcode,
          'conversionFactor': unit.conversionFactor,
          'price': change.price,
          'affectsInventory': unit.affectsInventory || enables,
          'allowsDecimalQuantity': unit.allowsDecimalQuantity,
          'isInventoryBaseUnit': unit.isInventoryBaseUnit || enables,
          'version': version++,
        });
      }
    }

    final limits = change.limits;
    if (limits != null &&
        (limits.minimum != latest.minimumStock ||
            limits.maximum != latest.maximumStock)) {
      await _variants.updateLimits(_productId, original.id, {
        'minimumStock': limits.minimum,
        'maximumStock': limits.maximum,
      });
    }

    final photo = change.photo;
    if (photo != null) {
      await ref
          .read(productImageRepositoryProvider)
          .uploadVariantImage(
            _productId,
            original.id,
            photo,
            altText: variantName(latest),
          );
    }
  }

  String? _textOrNull(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  Future<ProductDetailModel> _reload() {
    ref.invalidate(productDetailProvider(_productId));
    return ref.read(productDetailProvider(_productId).future);
  }

  Future<bool> _run(
    Future<void> Function(ProductDetailModel product) action,
  ) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final result = await AsyncValue.guard(() async {
      final product = await ref.read(productDetailProvider(_productId).future);
      await action(product);
    });
    if (ref.mounted) {
      ref.invalidate(productListProvider);
      try {
        await _reload();
      } catch (_) {}
    }
    if (ref.mounted) state = result;
    keepAlive.close();
    return !result.hasError;
  }
}

final variantActionProvider = NotifierProvider.autoDispose
    .family<VariantActionController, AsyncValue<void>, (String, VariantAction)>(
      VariantActionController.new,
    );
