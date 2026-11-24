import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:material_ui/material_ui.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      key: const Key('home-page'),
      child: Padding(
        padding: const EdgeInsets.all(CascaSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Inicio', style: textTheme.headlineMedium),
            const SizedBox(height: CascaSpacing.space2),
            Text(
              'Próximamente: el resumen de tu negocio.',
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
