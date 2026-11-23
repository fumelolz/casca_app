import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_overlay_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap({
  required bool visible,
  String? message,
  VoidCallback? onBackgroundTap,
}) {
  return MaterialApp(
    theme: CascaTheme.light,
    home: Scaffold(
      body: Stack(
        children: [
          if (onBackgroundTap != null)
            Center(
              child: TextButton(
                onPressed: onBackgroundTap,
                child: const Text('Fondo'),
              ),
            ),
          CascaOverlayLoader(
            visible: visible,
            heading: 'Bienvenido',
            message: message,
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('oculto no dibuja nada ni bloquea toques', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      _wrap(visible: false, onBackgroundTap: () => taps++),
    );
    await tester.tap(find.text('Fondo'));

    expect(find.text('Bienvenido'), findsNothing);
    expect(taps, 1);
  });

  testWidgets('visible muestra título y mensaje y bloquea el fondo', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      _wrap(
        visible: true,
        message: 'Preparando todo para ti',
        onBackgroundTap: () => taps++,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Fondo'), warnIfMissed: false);

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Preparando todo para ti'), findsOneWidget);
    expect(taps, 0);
  });

  testWidgets('sin mensaje no dibuja el texto secundario', (tester) async {
    await tester.pumpWidget(_wrap(visible: true));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Preparando todo para ti'), findsNothing);
  });

  testWidgets('al ocultarse hace fade y se retira del árbol', (tester) async {
    await tester.pumpWidget(_wrap(visible: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bienvenido'), findsOneWidget);

    await tester.pumpWidget(_wrap(visible: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Bienvenido'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bienvenido'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('con animaciones reducidas sigue mostrando el contenido', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _wrap(visible: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bienvenido'), findsOneWidget);
  });
}
