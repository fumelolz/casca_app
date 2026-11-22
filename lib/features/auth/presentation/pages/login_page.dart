import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:material_ui/material_ui.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: CascaRadius.sm,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bienvenido a Casca',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: CascaSpacing.space2),
              Text(
                'Accede a tu espacio de trabajo.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
