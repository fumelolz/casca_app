import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/data/models/product_variant_model.dart';
import 'package:casca_app/features/products/domain/product_variant_view_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_form_provider.dart';
import 'package:casca_app/features/products/presentation/providers/product_variant_actions_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/product_variant_list.dart';
import 'package:casca_app/features/products/presentation/widgets/variant_form_modal.dart';
import 'package:casca_app/features/products/presentation/widgets/variant_order_modal.dart';
import 'package:casca_app/features/products/presentation/widgets/variant_price_modal.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class ProductVariantsManager extends ConsumerStatefulWidget {
  const ProductVariantsManager({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductVariantsManager> createState() =>
      _ProductVariantsManagerState();
}

class _ProductVariantsManagerState
    extends ConsumerState<ProductVariantsManager> {
  final _selected = <String>{};

  void _select(Set<String> ids, bool selected) {
    setState(() => selected ? _selected.addAll(ids) : _selected.removeAll(ids));
  }

  Future<void> _openForm(
    ProductDetailModel product, [
    ProductVariantModel? variant,
  ]) {
    return showCascaModal<bool>(
      context: context,
      builder: (_) => VariantFormModal(product: product, variant: variant),
    );
  }

  Future<void> _openOrder(List<VariantOptionGroup> groups) {
    return showCascaModal<bool>(
      context: context,
      builder: (_) =>
          VariantOrderModal(productId: widget.productId, groups: groups),
    );
  }

  Future<void> _openPrices(Set<String> ids) async {
    final saved = await showCascaModal<bool>(
      context: context,
      builder: (_) =>
          VariantPriceModal(productId: widget.productId, variantIds: ids),
    );
    if ((saved ?? false) && mounted) setState(_selected.clear);
  }

  void _toggleStatus(ProductVariantModel variant) {
    ref
        .read(
          variantActionProvider((widget.productId, VariantAction.status))
              .notifier,
        )
        .changeStatus(variant.id, active: !isVariantActive(variant));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final detail = ref.watch(productDetailProvider(widget.productId));
    final status = ref.watch(
      variantActionProvider((widget.productId, VariantAction.status)),
    );
    final product = detail.value;
    if (product == null) return const SizedBox.shrink();

    final variants = sortVariants(product.variants);
    final ids = {for (final variant in variants) variant.id};
    final selected = _selected.intersection(ids);
    final groups = buildOptionGroups(variants);
    final valueCount = groups.fold(
      0,
      (sum, group) => sum + group.values.length,
    );
    final busy = status.isLoading || detail.isLoading;
    final error = status.error;

    return CascaCard(
      title: 'Variantes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          Text(
            'Cada variante tiene su propio precio, código de barras e inventario. Los cambios se guardan al momento.',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          Wrap(
            spacing: CascaSpacing.space2,
            runSpacing: CascaSpacing.space2,
            children: [
              CascaButton(
                label: 'Agregar variante',
                variant: CascaButtonVariant.secondary,
                onPressed: busy ? null : () => _openForm(product),
              ),
              if (valueCount > 1)
                CascaButton(
                  label: 'Ordenar',
                  variant: CascaButtonVariant.text,
                  onPressed: busy ? null : () => _openOrder(groups),
                ),
            ],
          ),
          if (error != null)
            Text(
              apiErrorMessage(
                error,
                'No fue posible cambiar el estado de la variante.',
              ),
              style: textTheme.bodyMedium?.copyWith(color: colors.danger),
            ),
          if (variants.length > 1) ...[
            Row(
              children: [
                CascaCheckbox(
                  value: selected.isEmpty
                      ? false
                      : selected.length == ids.length
                      ? true
                      : null,
                  semanticLabel: 'Seleccionar todas las variantes',
                  onChanged: (_) => _select(ids, selected.length != ids.length),
                ),
                Expanded(
                  child: Text(
                    selected.isEmpty
                        ? 'Seleccionar todas'
                        : '${selected.length} seleccionadas',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (groups.isNotEmpty)
              CascaSelect<(String, String)>(
                options: [
                  for (final group in groups)
                    for (final value in group.values)
                      CascaSelectOption(
                        value: (group.name, value),
                        label: '${group.name}: $value',
                      ),
                ],
                value: null,
                hintText: 'Seleccionar por valor',
                onChanged: (choice) => _select({
                  for (final variant in variants)
                    if (variant.options.any(
                      (option) =>
                          option.name == choice.$1 && option.value == choice.$2,
                    ))
                      variant.id,
                }, true),
              ),
          ],
          if (selected.isNotEmpty)
            Wrap(
              spacing: CascaSpacing.space2,
              runSpacing: CascaSpacing.space2,
              children: [
                CascaButton(
                  label: 'Cambiar precio',
                  onPressed: busy ? null : () => _openPrices(selected),
                ),
                CascaButton(
                  label: 'Limpiar',
                  variant: CascaButtonVariant.text,
                  onPressed: () => setState(_selected.clear),
                ),
              ],
            ),
          ProductVariantList(
            variants: variants,
            selected: selected,
            onSelect: _select,
            onEdit: busy ? null : (variant) => _openForm(product, variant),
            onToggleStatus: busy ? null : _toggleStatus,
          ),
        ],
      ),
    );
  }
}
