import 'package:casca_app/app/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'theme/casca_theme.dart';

class CascaApp extends ConsumerWidget {
  const CascaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Casca',
      debugShowCheckedModeBanner: false,
      theme: CascaTheme.light,
      darkTheme: CascaTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
