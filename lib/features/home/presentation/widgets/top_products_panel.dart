import 'dart:math';

import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/home/data/models/dashboard_summary_model.dart';
import 'package:casca_app/features/home/domain/dashboard_rules.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:material_ui/material_ui.dart';

const int _highlighted = 3;
const double _rankSize = 28;
const double _barHeight = 6;

class TopProductsPanel extends StatelessWidget {
  const TopProductsPanel({super.key, required this.products});

  final List<DashboardProductSale> products;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final most = products.fold(
      0.0,
      (highest, product) => max(highest, product.quantity),
    );

    return CascaCard(
      title: 'Lo más vendido hoy',
      child: products.isEmpty
          ? Text(
              'Aún no hay productos vendidos hoy.',
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            )
          : Column(
              spacing: CascaSpacing.space4,
              children: [
                for (final (index, product) in products.indexed)
                  _ProductRow(
                    position: index + 1,
                    product: product,
                    share: most <= 0 ? 0 : product.quantity / most,
                  ),
              ],
            ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.position,
    required this.product,
    required this.share,
  });

  final int position;
  final DashboardProductSale product;
  final double share;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final top = position <= _highlighted;
    final strong = textTheme.bodyMedium?.copyWith(
      fontWeight: CascaFontWeight.semibold,
    );

    return Row(
      spacing: CascaSpacing.space3,
      children: [
        Container(
          width: _rankSize,
          height: _rankSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: top ? colors.primary : colors.backgroundHover,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$position',
            style: textTheme.bodySmall?.copyWith(
              color: top ? colors.onPrimary : colors.textSecondary,
              fontWeight: CascaFontWeight.semibold,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CascaSpacing.space1,
            children: [
              Row(
                spacing: CascaSpacing.space3,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: top ? strong : textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    formatMoney(product.revenue),
                    style: top ? strong : textTheme.bodyMedium,
                  ),
                ],
              ),
              if (top)
                ClipRRect(
                  borderRadius: BorderRadius.circular(_barHeight),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: _barHeight,
                    color: colors.primary,
                    backgroundColor: colors.primarySoft,
                    semanticsLabel: 'Unidades de ${product.name}',
                  ),
                ),
              Text(
                soldLabel(product.quantity, formatQuantity(product.quantity)),
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
