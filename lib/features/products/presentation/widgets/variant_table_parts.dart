import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

const double variantTableCompactWidth = 560;
const double variantTableActionSize = 44;

TextStyle? variantTitleStyle(BuildContext context, {bool bold = false}) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    fontWeight: bold ? CascaFontWeight.semibold : CascaFontWeight.regular,
  );
}

class VariantTableColumn {
  const VariantTableColumn(this.label, this.flex);

  final String label;
  final int flex;
}

class VariantTableHeader extends StatelessWidget {
  const VariantTableHeader({
    super.key,
    required this.columns,
    this.leadingSpace = 0,
    this.trailingSpace = 0,
  });

  final List<VariantTableColumn> columns;
  final double leadingSpace;
  final double trailingSpace;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: context.casca.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: CascaSpacing.space2),
      child: Row(
        spacing: CascaSpacing.space2,
        children: [
          if (leadingSpace > 0) SizedBox(width: leadingSpace),
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Text(column.label, style: style),
            ),
          if (trailingSpace > 0) SizedBox(width: trailingSpace),
        ],
      ),
    );
  }
}

class VariantTableRow extends StatelessWidget {
  const VariantTableRow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space2),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.casca.border)),
      ),
      child: child,
    );
  }
}

class VariantGroupChevron extends StatelessWidget {
  const VariantGroupChevron({super.key, required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: variantTableActionSize,
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
    );
  }
}
