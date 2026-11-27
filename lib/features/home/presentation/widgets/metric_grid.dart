import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/home/data/models/dashboard_summary_model.dart';
import 'package:casca_app/features/home/domain/dashboard_rules.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

const double _wideBreakpoint = 640;
const double _badgeSize = 44;

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.blocks, required this.summary});

  final List<DashboardBlock> blocks;
  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= _wideBreakpoint ? 3 : 1;
        final rows = [
          for (var start = 0; start < blocks.length; start += columns)
            blocks.skip(start).take(columns).toList(),
        ];

        return Column(
          spacing: CascaSpacing.space3,
          children: [
            for (final row in rows)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: CascaSpacing.space3,
                  children: [
                    for (final block in row)
                      Expanded(child: _tile(context, block)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, DashboardBlock block) {
    final colors = context.casca;

    return switch (block) {
      DashboardBlock.ordersToday => _MetricTile(
        label: 'Ventas realizadas',
        value: '${summary.todayOrders}',
        caption: 'completadas hoy',
        icon: CascaIcons.receipt,
        color: colors.info,
        background: colors.infoSoft,
      ),
      DashboardBlock.averageTicket => _MetricTile(
        label: 'Ticket promedio',
        value: formatMoney(summary.averageTicket),
        caption: 'importe por venta',
        icon: CascaIcons.basketShopping,
        color: colors.warning,
        background: colors.warningSoft,
      ),
      _ => _MetricTile(
        label: 'Utilidad estimada',
        value: formatMoney(summary.todayProfit),
        caption: 'sobre las ventas del día',
        icon: CascaIcons.money,
        color: colors.success,
        background: colors.successSoft,
      ),
    };
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final String caption;
  final String icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CascaCard(
      padding: const EdgeInsets.all(CascaSpacing.space4),
      child: Row(
        spacing: CascaSpacing.space3,
        children: [
          Container(
            width: _badgeSize,
            height: _badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: CascaRadius.md,
            ),
            child: CascaIcon(icon, size: CascaSpacing.space5, color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodyMedium),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: CascaFontWeight.semibold,
                    ),
                  ),
                ),
                Text(caption, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
