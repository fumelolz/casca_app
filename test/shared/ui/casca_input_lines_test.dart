import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<TextField> _pump(WidgetTester tester, CascaInput input) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: CascaTheme.light,
      home: Scaffold(body: input),
    ),
  );
  return tester.widget<TextField>(find.byType(TextField));
}

void main() {
  testWidgets('por defecto es de una sola línea', (tester) async {
    final field = await _pump(tester, const CascaInput());

    expect(field.minLines, 1);
    expect(field.maxLines, 1);
  });

  testWidgets('con varias líneas se comporta como área de texto', (
    tester,
  ) async {
    final field = await _pump(tester, const CascaInput(lines: 3));

    expect(field.minLines, 3);
    expect(field.maxLines, 3);
    expect(field.keyboardType, TextInputType.multiline);
  });

  testWidgets('una contraseña siempre es de una línea', (tester) async {
    final field = await _pump(
      tester,
      const CascaInput(password: true, lines: 3),
    );

    expect(field.maxLines, 1);
  });
}
