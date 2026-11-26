import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:material_ui/material_ui.dart';

const double _letterSpacing = 0.6;

class BusinessSectionTitle extends StatelessWidget {
  const BusinessSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      semanticsLabel: title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: context.casca.textSecondary,
        fontWeight: CascaFontWeight.semibold,
        letterSpacing: _letterSpacing,
      ),
    );
  }
}
