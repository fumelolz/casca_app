import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/products/domain/product_variant_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_variants_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_fields.dart';
import 'package:casca_app/features/products/presentation/widgets/product_variant_option_editor.dart';
import 'package:casca_app/features/products/presentation/widgets/product_variants_table.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class ProductVariantsSection extends ConsumerWidget {
  const ProductVariantsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(productVariantsProvider);
    final controller = ref.read(productVariantsProvider.notifier);
    final options = state.options;
    final editing = state.editing;
    final groupBy = state.groupBy;

    Widget editor(int index) {
      return ProductVariantOptionEditor(
        key: ValueKey('option-editor-$index'),
        option: index == newOptionIndex ? null : options[index],
        otherOptions: [
          for (final (other, option) in options.indexed)
            if (other != index) option,
        ],
        onSave: controller.saveOption,
        onRemove: controller.removeEditingOption,
      );
    }

    return CascaCard(
      title: 'Variantes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          Text(
            'Define opciones como Color o Talla y se generarán todas las combinaciones.',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          for (final (index, option) in options.indexed)
            editing == index
                ? editor(index)
                : _OptionSummary(
                    option: option,
                    onTap: () => controller.edit(index),
                  ),
          if (editing == newOptionIndex) editor(newOptionIndex),
          if (editing == null && options.length < maxVariantOptions)
            Align(
              alignment: Alignment.centerLeft,
              child: CascaButton(
                label: options.isEmpty ? 'Añadir opciones' : 'Agregar opción',
                variant: CascaButtonVariant.secondary,
                onPressed: () => controller.edit(newOptionIndex),
              ),
            ),
          if (options.length > 1)
            ProductField(
              label: 'Agrupar por',
              child: CascaSelect<String>(
                options: [
                  for (final option in options)
                    CascaSelectOption(value: option.name, label: option.name),
                ],
                value: groupBy,
                onChanged: controller.groupBy,
              ),
            ),
          if (state.variants.isNotEmpty) const ProductVariantsTable(),
        ],
      ),
    );
  }
}

class _OptionSummary extends StatelessWidget {
  const _OptionSummary({required this.option, required this.onTap});

  final VariantOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Editar opción ${option.name}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(CascaSpacing.space4),
            decoration: BoxDecoration(
              borderRadius: CascaRadius.md,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: CascaFontWeight.semibold,
                  ),
                ),
                const SizedBox(height: CascaSpacing.space2),
                Wrap(
                  spacing: CascaSpacing.space2,
                  runSpacing: CascaSpacing.space2,
                  children: [
                    for (final value in option.values)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CascaSpacing.space3,
                          vertical: CascaSpacing.space1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.backgroundHover,
                          borderRadius: CascaRadius.sm,
                        ),
                        child: Text(value, style: textTheme.bodySmall),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
