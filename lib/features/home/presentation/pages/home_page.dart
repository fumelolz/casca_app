import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/shared/ui/casca_link.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: CascaLink(
          label: 'Cerrar sesión',
          onTap: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ),
    );
  }
}
