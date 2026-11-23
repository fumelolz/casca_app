import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:material_ui/material_ui.dart';

class CascaLink extends StatelessWidget {
  const CascaLink({
    super.key,
    required this.label,
    required this.onTap,
    this.textBefore,
    this.textAfter,
    this.fontSize = CascaFontSize.sm,
  });

  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final String? textBefore;
  final String? textAfter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.casca;

    final link = Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: colors.info,
              fontSize: fontSize,
              fontWeight: CascaFontWeight.semibold,
            ),
          ),
        ),
      ),
    );

    if (textBefore == null && textAfter == null) return link;

    return Text.rich(
      TextSpan(
        style: textTheme.bodyLarge?.copyWith(
          color: colors.textSecondary,
          fontSize: fontSize,
        ),
        children: [
          if (textBefore != null) TextSpan(text: textBefore),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: link,
          ),
          if (textAfter != null) TextSpan(text: textAfter),
        ],
      ),
    );
  }
}
