import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: CascaTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('ejecuta onPressed al tocar', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      _wrap(CascaButton(label: 'Guardar', onPressed: () => taps++)),
    );
    await tester.tap(find.text('Guardar'));

    expect(taps, 1);
  });

  testWidgets('no ejecuta onPressed mientras carga y muestra el spinner', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      _wrap(
        CascaButton(label: 'Guardar', loading: true, onPressed: () => taps++),
      ),
    );
    await tester.tap(find.text('Guardar'));

    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('sin onPressed queda deshabilitado', (tester) async {
    await tester.pumpWidget(
      _wrap(const CascaButton(label: 'Guardar', onPressed: null)),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(button.onPressed, isNull);
  });

  testWidgets('fullWidth ocupa todo el ancho disponible', (tester) async {
    tester.view.physicalSize = const Size(500, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(CascaButton(label: 'Guardar', fullWidth: true, onPressed: () {})),
    );

    expect(tester.getSize(find.byType(FilledButton)).width, 500);
  });
}
