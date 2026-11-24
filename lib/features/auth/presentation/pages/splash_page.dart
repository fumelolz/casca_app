import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/layout/brand_lockup.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final failed =
        ref.watch(authControllerProvider).status == AuthStatus.connectionFailed;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 120, iconSize: 60),
            if (failed) ...[
              const SizedBox(height: CascaSpacing.space6),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CascaSpacing.space6,
                ),
                child: Text(
                  'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: colors.textMuted),
                ),
              ),
              const SizedBox(height: CascaSpacing.space5),
              CascaButton(
                label: 'Reintentar',
                variant: CascaButtonVariant.primary,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).restoreSession(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
