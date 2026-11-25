import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:material_ui/material_ui.dart';

class CascaCard extends StatelessWidget {
  const CascaCard({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(CascaSpacing.space5),
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final heading = title;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: CascaRadius.lg,
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        boxShadow: CascaShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heading != null) ...[
            Text(heading, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: CascaSpacing.space4),
          ],
          child,
        ],
      ),
    );
  }
}
