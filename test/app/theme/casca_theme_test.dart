import 'package:casca_app/app/theme/casca_colors.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('el tema claro y oscuro registran los colores de Casca', () {
    expect(CascaTheme.light.extension<CascaColors>(), CascaColors.light);
    expect(CascaTheme.dark.extension<CascaColors>(), CascaColors.dark);
  });

  test('el esquema de color usa el primario de la marca', () {
    expect(CascaTheme.light.colorScheme.primary, CascaColors.light.primary);
    expect(CascaTheme.dark.colorScheme.primary, CascaColors.dark.primary);
  });

  testWidgets('context.casca devuelve los colores del tema activo', (
    tester,
  ) async {
    late CascaColors resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: CascaTheme.dark,
        home: Builder(
          builder: (context) {
            resolved = context.casca;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved.background, CascaColors.dark.background);
  });
}
