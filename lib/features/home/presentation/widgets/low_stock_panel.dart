import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/home/data/models/dashboard_summary_model.dart';
import 'package:casca_app/features/home/domain/dashboard_rules.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

const int _collapsedCount = 5;

class LowStockPanel extends StatefulWidget {
  const LowStockPanel({super.key, required this.products});

  final List<DashboardLowStock> products;

  @override
  State<LowStockPanel> createState() => _LowStockPanelState();
}

class _LowStockPanelState extends State<LowStockPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final products = byUrgency(widget.products);
    final soldOut = products.where((product) => product.stock <= 0).length;
    final low = products.length - soldOut;
    final visible = _expanded ? products : products.take(_collapsedCount);

    return CascaCard(
      title: 'Por resurtir',
      child: products.isEmpty
          ? Text(
              'No hay productos por debajo del mínimo.',
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: CascaSpacing.space3,
                  children: [
                    Expanded(
                      child: _Counter(
                        count: soldOut,
                        label: 'Agotados',
                        color: colors.danger,
                        background: colors.dangerSoft,
                      ),
                    ),
                    Expanded(
                      child: _Counter(
                        count: low,
                        label: 'Bajo el mínimo',
                        color: colors.warning,
                        background: colors.warningSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CascaSpacing.space2),
                for (final (index, product) in visible.indexed) ...[
                  if (index > 0) Divider(height: 1, color: colors.border),
                  _RestockRow(product),
                ],
                if (products.length > _collapsedCount)
                  Center(
                    child: CascaButton(
                      label: _expanded
                          ? 'Ver menos'
                          : 'Ver los ${products.length}',
                      variant: CascaButtonVariant.text,
                      size: CascaButtonSize.sm,
                      onPressed: () => setState(() => _expanded = !_expanded),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.count,
    required this.label,
    required this.color,
    required this.background,
  });

  final int count;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(CascaSpacing.space3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: CascaRadius.md,
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: CascaFontWeight.semibold,
            ),
          ),
          Text(label, style: textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _RestockRow extends StatelessWidget {
  const _RestockRow(this.product);

  final DashboardLowStock product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final soldOut = product.stock <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space3),
      child: Row(
        spacing: CascaSpacing.space3,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
                Text(
                  'Mínimo ${formatQuantity(product.minimumStock)}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          CascaStatusChip(
            label: soldOut
                ? 'Agotado'
                : 'Quedan ${formatQuantity(product.stock)}',
            tone: soldOut ? CascaChipTone.danger : CascaChipTone.warning,
          ),
        ],
      ),
    );
  }
}
