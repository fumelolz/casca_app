import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:material_ui/material_ui.dart';

class ModulePlaceholderPage extends StatelessWidget {
  const ModulePlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CascaSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: textTheme.headlineMedium),
            const SizedBox(height: CascaSpacing.space2),
            Text(
              'Próximamente.',
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
