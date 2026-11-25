import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/products/domain/product_list_rules.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:material_ui/material_ui.dart';

const double _barHeight = 6;
const double _barMaxWidth = 160;

class StockLevelIndicator extends StatelessWidget {
  const StockLevelIndicator({
    super.key,
    required this.stock,
    required this.minimumStock,
    this.maximumStock,
  });

  final double stock;
  final double minimumStock;
  final double? maximumStock;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final level = stockLevel(stock, minimumStock, maximumStock);
    final percentage = level.percentage;
    final (textColor, barColor) = switch (level.status) {
      StockStatus.optimal || StockStatus.ok => (colors.success, colors.success),
      StockStatus.moderate => (colors.textSecondary, colors.success),
      StockStatus.low => (colors.warning, colors.warning),
      StockStatus.critical || StockStatus.out => (colors.danger, colors.danger),
    };
    final status = percentage == null
        ? level.status.label
        : '${level.status.label} ($percentage%)';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatQuantity(stock)} uds',
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: CascaFontWeight.semibold,
          ),
        ),
        Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(color: textColor),
        ),
        if (percentage != null) ...[
          const SizedBox(height: CascaSpacing.space1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _barMaxWidth),
            child: ClipRRect(
              borderRadius: CascaRadius.sm,
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: _barHeight,
                color: barColor,
                backgroundColor: colors.backgroundHover,
                semanticsLabel: 'Nivel de stock: $status',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
