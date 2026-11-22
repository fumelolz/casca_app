import 'package:casca_app/features/auth/presentation/pages/login_page.dart';
import 'package:material_ui/material_ui.dart';

import 'theme/casca_theme.dart';

class CascaApp extends StatelessWidget {
  const CascaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casca',
      debugShowCheckedModeBanner: false,
      theme: CascaTheme.light,
      darkTheme: CascaTheme.dark,
      themeMode: ThemeMode.system,
      home: const LoginPage(),
    );
  }
}
