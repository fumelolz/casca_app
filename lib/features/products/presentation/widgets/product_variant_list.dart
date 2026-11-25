import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/products/data/models/product_variant_model.dart';
import 'package:casca_app/features/products/domain/product_variant_view_rules.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_fields.dart';
import 'package:casca_app/features/products/presentation/widgets/product_thumbnail.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

const double _compactWidth = 560;
const double _actionsSize = 44;
const int _titleFlex = 4;
const int _skuFlex = 3;
const int _statusFlex = 3;
const int _priceFlex = 2;
const int _stockFlex = 2;

class ProductVariantList extends StatefulWidget {
  const ProductVariantList({
    super.key,
    required this.variants,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final List<ProductVariantModel> variants;
  final Set<String> selected;
  final void Function(Set<String> ids, bool selected) onSelect;
  final ValueChanged<ProductVariantModel>? onEdit;
  final ValueChanged<ProductVariantModel>? onToggleStatus;

  @override
  State<ProductVariantList> createState() => _ProductVariantListState();
}

class _ProductVariantListState extends State<ProductVariantList> {
  final _expanded = <String>{};
  String? _groupBy;

  Widget _variant(ProductVariantModel variant, String title, bool compact) {
    final edit = widget.onEdit;
    final toggle = widget.onToggleStatus;
    final price = variant.saleUnit?.price;
    final active = isVariantActive(variant);

    return _Line(
      key: ValueKey('variant-row-${variant.id}'),
      compact: compact,
      selected: widget.selected.contains(variant.id),
      selectionLabel: 'Seleccionar ${variantName(variant)}',
      onSelected: (selected) => widget.onSelect({variant.id}, selected),
      leading: ProductThumbnail(image: variant.image),
      title: title,
      sku: variant.sku,
      status: CascaStatusChip(
        label: variantStatusLabel(variant.status),
        tone: active ? CascaChipTone.success : CascaChipTone.neutral,
      ),
      price: price == null ? '—' : formatMoney(price),
      stock: formatQuantity(variant.stock),
      trailing: CascaActionMenu(
        semanticLabel: 'Acciones de ${variantName(variant)}',
        sections: [
          CascaActionMenuSection(
            items: [
              CascaActionMenuItem(
                id: 'edit',
                label: 'Editar',
                icon: CascaIcons.pencilSimple,
                disabled: edit == null,
                onSelected: () => edit?.call(variant),
              ),
              CascaActionMenuItem(
                id: 'status',
                label: active ? 'Desactivar' : 'Activar',
                icon: active ? CascaIcons.eyeSlash : CascaIcons.eye,
                disabled:
                    toggle == null || variant.status == historicalVariantStatus,
                onSelected: () => toggle?.call(variant),
              ),
            ],
          ),
        ],
        child: SizedBox.square(
          dimension: _actionsSize,
          child: Center(
            child: CascaIcon(
              CascaIcons.dotsThree,
              size: CascaSpacing.space5,
              color: context.casca.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _group(VariantRowGroup group, String groupBy, bool compact) {
    final id = '$groupBy:${group.title}';
    final expanded = _expanded.contains(id);
    final prices = group.prices;
    final count = group.variants.length;
    final selectedCount = group.ids.intersection(widget.selected).length;

    void toggle() => setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });

    return Column(
      key: ValueKey('variant-group-$id'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(
          compact: compact,
          bold: true,
          selected: selectedCount == 0
              ? false
              : selectedCount == count
              ? true
              : null,
          selectionLabel: 'Seleccionar todas las variantes de ${group.title}',
          onSelected: (_) => widget.onSelect(group.ids, selectedCount != count),
          title: group.title,
          sku: '$count ${count == 1 ? 'variante' : 'variantes'}',
          status: Text(
            '${group.activeCount} de $count activas',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          price: prices.isEmpty
              ? '—'
              : prices.first == prices.last
              ? formatMoney(prices.first)
              : '${formatMoney(prices.first)} - ${formatMoney(prices.last)}',
          stock: formatQuantity(group.totalStock),
          onTap: toggle,
          trailing: Semantics(
            button: true,
            expanded: expanded,
            label: expanded ? 'Ocultar ${group.title}' : 'Ver ${group.title}',
            excludeSemantics: true,
            child: InkResponse(
              onTap: toggle,
              radius: _actionsSize / 2,
              child: SizedBox.square(
                dimension: _actionsSize,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: expanded ? 2 : 0,
                    child: CascaIcon(
                      CascaIcons.chevronDown,
                      size: CascaSpacing.space4,
                      color: context.casca.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: CascaSpacing.space4),
            child: Column(
              children: [
                for (final variant in group.variants)
                  _variant(variant, variantRowTitle(variant, groupBy), compact),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = buildOptionGroups(widget.variants);
    final names = [for (final option in options) option.name];
    final groupBy = names.contains(_groupBy) ? _groupBy : names.firstOrNull;

    if (widget.variants.isEmpty) {
      return Text(
        'Este producto aún no tiene variantes.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < _compactWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (names.length > 1) ...[
              ProductField(
                label: 'Agrupar por',
                child: CascaSelect<String>(
                  options: [
                    for (final name in names)
                      CascaSelectOption(value: name, label: name),
                  ],
                  value: groupBy,
                  onChanged: (name) => setState(() => _groupBy = name),
                ),
              ),
              const SizedBox(height: CascaSpacing.space3),
            ],
            if (!compact) const _Header(),
            if (names.length > 1)
              for (final group in buildRowGroups(widget.variants, groupBy!))
                _group(group, groupBy, compact)
            else
              for (final variant in widget.variants)
                _variant(variant, variantName(variant), compact),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: context.casca.textSecondary);
    Widget column(int flex, String text) => Expanded(
      flex: flex,
      child: Text(text, style: style),
    );

    return Row(
      spacing: CascaSpacing.space2,
      children: [
        const SizedBox(width: _actionsSize),
        column(_titleFlex, 'Variante'),
        column(_skuFlex, 'SKU'),
        column(_statusFlex, 'Estado'),
        column(_priceFlex, 'Precio'),
        column(_stockFlex, 'Stock'),
        const SizedBox(width: _actionsSize),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.compact,
    required this.selected,
    required this.selectionLabel,
    required this.onSelected,
    required this.title,
    required this.sku,
    required this.status,
    required this.price,
    required this.stock,
    required this.trailing,
    this.leading,
    this.bold = false,
    this.onTap,
  });

  final bool compact;
  final bool? selected;
  final String selectionLabel;
  final ValueChanged<bool> onSelected;
  final Widget? leading;
  final String title;
  final String sku;
  final Widget status;
  final String price;
  final String stock;
  final Widget trailing;
  final bool bold;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final titleStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? CascaFontWeight.semibold : CascaFontWeight.regular,
    );
    final image = leading;

    final name = Row(
      spacing: CascaSpacing.space2,
      children: [
        ?image,
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          ),
        ),
      ],
    );

    final content = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CascaSpacing.space1,
            children: [
              name,
              Text('$price · Stock $stock', style: textTheme.bodyMedium),
              Text(sku, style: muted),
              status,
            ],
          )
        : Row(
            spacing: CascaSpacing.space2,
            children: [
              Expanded(flex: _titleFlex, child: name),
              Expanded(
                flex: _skuFlex,
                child: Text(sku, style: muted, overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: _statusFlex,
                child: Align(alignment: Alignment.centerLeft, child: status),
              ),
              Expanded(
                flex: _priceFlex,
                child: Text(price, style: textTheme.bodyMedium),
              ),
              Expanded(
                flex: _stockFlex,
                child: Text(stock, style: textTheme.bodyMedium),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space2),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        spacing: CascaSpacing.space2,
        children: [
          CascaCheckbox(
            value: selected,
            semanticLabel: selectionLabel,
            onChanged: onSelected,
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: content,
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
