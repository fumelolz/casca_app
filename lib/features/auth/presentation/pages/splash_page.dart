import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/layout/brand_lockup.dart';
import 'package:material_ui/material_ui.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.casca.background,
      body: const Center(child: BrandMark(size: 120, iconSize: 60)),
    );
  }
}
