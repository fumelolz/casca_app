import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/products/domain/product_form_rules.dart';
import 'package:casca_app/features/products/domain/product_variant_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_variants_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/variant_table_parts.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const int _titleFlex = 3;
const int _cellFlex = 2;
const List<String> _columns = ['Precio', 'Costo', 'Disponible'];

class ProductVariantsTable extends ConsumerStatefulWidget {
  const ProductVariantsTable({super.key});

  @override
  ConsumerState<ProductVariantsTable> createState() =>
      _ProductVariantsTableState();
}

class _ProductVariantsTableState extends ConsumerState<ProductVariantsTable> {
  final _expanded = <String>{};

  ProductVariantsController get _controller =>
      ref.read(productVariantsProvider.notifier);

  Widget _row(
    ProductVariantDraft variant,
    String title,
    bool compact, {
    bool grouped = false,
  }) {
    final keys = {variant.key};

    return _VariantLine(
      key: ValueKey('variant-${variant.key}'),
      compact: compact,
      title: Text(title, style: variantTitleStyle(context)),
      trailing: grouped && !compact
          ? const SizedBox(width: variantTableActionSize)
          : null,
      cells: [
        _AmountCell(
          key: Key('variant-price-${variant.key}'),
          value: variant.price,
          hint: '0.00',
          prefix: r'$',
          onChanged: (price) => _controller.setPrice(keys, price ?? 0),
        ),
        _AmountCell(
          key: Key('variant-cost-${variant.key}'),
          value: variant.cost,
          hint: '0.00',
          prefix: r'$',
          onChanged: (cost) => _controller.setCost(keys, cost ?? 0),
        ),
        _AmountCell(
          key: Key('variant-stock-${variant.key}'),
          value: variant.stock,
          hint: '0',
          decimals: false,
          onChanged: (stock) => _controller.setStock(keys, stock ?? 0),
        ),
      ],
    );
  }

  Widget _group(VariantGroup group, String groupBy, bool compact) {
    final id = '$groupBy:${group.title}';
    final expanded = _expanded.contains(id);
    final price = AmountSummary.of(group.variants.map((v) => v.price));
    final cost = AmountSummary.of(group.variants.map((v) => v.cost));
    final stock = group.variants.fold(0.0, (sum, v) => sum + v.stock);

    void toggle() => setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });

    return Column(
      key: ValueKey('group-$id'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _VariantLine(
          compact: compact,
          title: _GroupTitle(
            title: group.title,
            count: group.variants.length,
            expanded: expanded,
            onTap: toggle,
          ),
          trailing: ExcludeSemantics(
            child: InkResponse(
              onTap: toggle,
              radius: variantTableActionSize / 2,
              child: VariantGroupChevron(expanded: expanded),
            ),
          ),
          cells: [
            _AmountCell(
              key: Key('group-price-${group.title}'),
              value: price.isMixed ? null : price.min,
              hint: price.text,
              prefix: r'$',
              onChanged: (value) {
                if (value != null) _controller.setPrice(group.keys, value);
              },
            ),
            _AmountCell(
              key: Key('group-cost-${group.title}'),
              value: cost.isMixed ? null : cost.min,
              hint: cost.text,
              prefix: r'$',
              onChanged: (value) {
                if (value != null) _controller.setCost(group.keys, value);
              },
            ),
            Padding(
              key: Key('group-stock-${group.title}'),
              padding: const EdgeInsets.symmetric(
                horizontal: CascaSpacing.space3,
                vertical: CascaSpacing.space2,
              ),
              child: Text(
                formatQuantity(stock),
                style: variantTitleStyle(context),
              ),
            ),
          ],
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: CascaSpacing.space4),
            child: Column(
              children: [
                for (final variant in group.variants)
                  _row(
                    variant,
                    variantTitleWithin(variant, groupBy),
                    compact,
                    grouped: true,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productVariantsProvider);
    final groupBy = state.groupBy;
    if (groupBy == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < variantTableCompactWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact)
              VariantTableHeader(
                trailingSpace: state.options.length > 1
                    ? variantTableActionSize
                    : 0,
                columns: [
                  const VariantTableColumn('Variante', _titleFlex),
                  for (final column in _columns)
                    VariantTableColumn(column, _cellFlex),
                ],
              ),
            if (state.options.length > 1)
              for (final group in groupVariants(state.variants, groupBy))
                _group(group, groupBy, compact)
            else
              for (final variant in state.variants)
                _row(variant, variant.label, compact),
          ],
        );
      },
    );
  }
}

class _VariantLine extends StatelessWidget {
  const _VariantLine({
    super.key,
    required this.compact,
    required this.title,
    required this.cells,
    this.trailing,
  });

  final bool compact;
  final Widget title;
  final List<Widget> cells;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.casca.textSecondary);
    final content = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: title),
                  ?trailing,
                ],
              ),
              const SizedBox(height: CascaSpacing.space2),
              Row(
                spacing: CascaSpacing.space2,
                children: [
                  for (final (index, cell) in cells.indexed)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_columns[index], style: labelStyle),
                          const SizedBox(height: CascaSpacing.space1),
                          cell,
                        ],
                      ),
                    ),
                ],
              ),
            ],
          )
        : Row(
            spacing: CascaSpacing.space2,
            children: [
              Expanded(flex: _titleFlex, child: title),
              for (final cell in cells) Expanded(flex: _cellFlex, child: cell),
              ?trailing,
            ],
          );

    return VariantTableRow(child: content);
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      expanded: expanded,
      label: '$title, $count variantes',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: variantTitleStyle(context, bold: true)),
              Text(
                '$count variantes',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountCell extends StatefulWidget {
  const _AmountCell({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.decimals = true,
    this.prefix,
  });

  final double? value;
  final String hint;
  final String? prefix;
  final ValueChanged<double?> onChanged;
  final bool decimals;

  @override
  State<_AmountCell> createState() => _AmountCellState();
}

class _AmountCellState extends State<_AmountCell> {
  late final _controller = TextEditingController(text: _format(widget.value));
  bool _focused = false;

  static String _format(double? value) {
    if (value == null || value == 0) return '';
    return formatQuantity(value).replaceAll(',', '');
  }

  void _syncWithValue() {
    final value = widget.value;
    final typed = parseAmount(_controller.text);
    final outdated = value == null
        ? _controller.text.isNotEmpty
        : (typed ?? 0) != value;
    if (outdated) _controller.text = _format(value);
  }

  @override
  void didUpdateWidget(_AmountCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focused) _syncWithValue();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) {
        _focused = focused;
        if (!focused) _syncWithValue();
      },
      child: CascaInput(
        controller: _controller,
        prefixText: widget.prefix,
        hintText: widget.hint,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimals),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(widget.decimals ? r'[0-9.]' : r'[0-9]'),
          ),
        ],
        textInputAction: TextInputAction.next,
        onChanged: (text) => widget.onChanged(parseAmount(text)),
      ),
    );
  }
}
