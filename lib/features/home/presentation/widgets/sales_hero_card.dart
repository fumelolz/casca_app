import 'dart:math';

import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/home/data/models/dashboard_summary_model.dart';
import 'package:casca_app/features/home/domain/dashboard_rules.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

const double _chartHeight = 140;
const double _columnWidth = 52;
const double _minColumnHeight = 6;
const double _previousAlpha = 0.3;

class SalesHeroCard extends StatelessWidget {
  const SalesHeroCard({super.key, required this.summary});

  final DashboardSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final highest = max(summary.todayTotal, summary.yesterdayTotal);
    final difference = summary.todayTotal - summary.yesterdayTotal;

    Widget column(String label, double amount, Color color) {
      final ratio = highest <= 0 ? 0.0 : amount / highest;

      return Semantics(
        label: '$label: ${formatMoney(amount)}',
        excludeSemantics: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: CascaSpacing.space2,
          children: [
            Container(
              width: _columnWidth,
              height: max(_minColumnHeight, _chartHeight * ratio),
              decoration: BoxDecoration(
                color: color,
                borderRadius: CascaRadius.md,
              ),
            ),
            Text(label, style: textTheme.bodySmall),
          ],
        ),
      );
    }

    return CascaCard(
      title: 'Ventas de hoy',
      child: Row(
        spacing: CascaSpacing.space4,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CascaSpacing.space2,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMoney(summary.todayTotal),
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: CascaFontSize.xxl,
                      fontWeight: CascaFontWeight.semibold,
                    ),
                  ),
                ),
                CascaStatusChip(
                  label: changeLabel(summary.percentageChange),
                  tone: difference < 0
                      ? CascaChipTone.danger
                      : difference > 0
                      ? CascaChipTone.success
                      : CascaChipTone.neutral,
                ),
                Text(
                  differenceLabel(difference, formatMoney(difference.abs())),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: CascaSpacing.space4,
            children: [
              column(
                'Ayer',
                summary.yesterdayTotal,
                colors.primary.withValues(alpha: _previousAlpha),
              ),
              column('Hoy', summary.todayTotal, colors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
