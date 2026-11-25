import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/products/domain/product_form_rules.dart';
import 'package:casca_app/features/products/domain/product_variant_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_variants_provider.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _compactWidth = 480;
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

  Widget _row(ProductVariantDraft variant, String title, bool compact) {
    final keys = {variant.key};

    return _VariantLine(
      key: ValueKey('variant-${variant.key}'),
      compact: compact,
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      cells: [
        _AmountCell(
          key: Key('variant-price-${variant.key}'),
          value: variant.price,
          hint: '0.00',
          onChanged: (price) => _controller.setPrice(keys, price ?? 0),
        ),
        _AmountCell(
          key: Key('variant-cost-${variant.key}'),
          value: variant.cost,
          hint: '0.00',
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
    final stock = AmountSummary.of(group.variants.map((v) => v.stock));

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
            onTap: () => setState(() {
              if (!_expanded.remove(id)) _expanded.add(id);
            }),
          ),
          cells: [
            _AmountCell(
              key: Key('group-price-${group.title}'),
              value: price.isMixed ? null : price.min,
              hint: price.text,
              onChanged: (value) {
                if (value != null) _controller.setPrice(group.keys, value);
              },
            ),
            _AmountCell(
              key: Key('group-cost-${group.title}'),
              value: cost.isMixed ? null : cost.min,
              hint: cost.text,
              onChanged: (value) {
                if (value != null) _controller.setCost(group.keys, value);
              },
            ),
            _AmountCell(
              key: Key('group-stock-${group.title}'),
              value: stock.isMixed ? null : stock.min,
              hint: stock.text,
              enabled: false,
              onChanged: (_) {},
            ),
          ],
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: CascaSpacing.space4),
            child: Column(
              children: [
                for (final variant in group.variants)
                  _row(variant, variantTitleWithin(variant, groupBy), compact),
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
        final compact = constraints.maxWidth < _compactWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact) const _Header(),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: context.casca.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: CascaSpacing.space2),
      child: Row(
        spacing: CascaSpacing.space2,
        children: [
          Expanded(
            flex: _titleFlex,
            child: Text('Variante', style: style),
          ),
          for (final column in _columns)
            Expanded(
              flex: _cellFlex,
              child: Text(column, style: style),
            ),
        ],
      ),
    );
  }
}

class _VariantLine extends StatelessWidget {
  const _VariantLine({
    super.key,
    required this.compact,
    required this.title,
    required this.cells,
  });

  final bool compact;
  final Widget title;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final labelStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: colors.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space3),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
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
                for (final cell in cells)
                  Expanded(flex: _cellFlex, child: cell),
              ],
            ),
    );
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: CascaFontWeight.semibold,
                      ),
                    ),
                    Text(
                      '$count variantes',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: CascaSpacing.space7,
                height: CascaSpacing.space7,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.backgroundHover,
                  borderRadius: CascaRadius.sm,
                ),
                child: RotatedBox(
                  quarterTurns: expanded ? 2 : 0,
                  child: CascaIcon(
                    CascaIcons.chevronDown,
                    size: CascaSpacing.space4,
                    color: colors.textSecondary,
                  ),
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
    this.enabled = true,
  });

  final double? value;
  final String hint;
  final ValueChanged<double?> onChanged;
  final bool decimals;
  final bool enabled;

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
        hintText: widget.hint,
        enabled: widget.enabled,
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
