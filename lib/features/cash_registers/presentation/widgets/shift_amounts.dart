import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:material_ui/material_ui.dart';

class ShiftDifference extends StatelessWidget {
  const ShiftDifference(this.difference, {super.key});

  final double? difference;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final difference = this.difference;
    if (difference == null) return Text('—', style: textTheme.bodyMedium);

    final (label, color) = difference == 0
        ? ('Sin diferencia', colors.success)
        : difference < 0
        ? ('Faltan ${formatMoney(-difference)}', colors.danger)
        : ('Sobran ${formatMoney(difference)}', colors.warning);

    return Text(
      label,
      textAlign: TextAlign.end,
      style: textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: CascaFontWeight.medium,
      ),
    );
  }
}

class ShiftAmountRow extends StatelessWidget {
  const ShiftAmountRow(
    this.label,
    this.amount, {
    super.key,
    this.strong = false,
  });

  final String label;
  final double amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = strong ? textTheme.titleMedium : textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CascaSpacing.space3,
        children: [
          Expanded(child: Text(label, style: style)),
          Text(formatMoney(amount), style: style),
        ],
      ),
    );
  }
}
