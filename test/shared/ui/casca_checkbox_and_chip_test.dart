import 'dart:ui' show CheckedState;

import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: CascaTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('CascaCheckbox', () {
    testWidgets('al tocar entrega el valor contrario', (tester) async {
      bool? received;
      await _pump(
        tester,
        CascaCheckbox(
          value: false,
          semanticLabel: 'Aceptar',
          onChanged: (value) => received = value,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Aceptar'));

      expect(received, isTrue);
    });

    testWidgets('marcada entrega falso al tocar', (tester) async {
      bool? received;
      await _pump(
        tester,
        CascaCheckbox(
          value: true,
          semanticLabel: 'Aceptar',
          onChanged: (value) => received = value,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Aceptar'));

      expect(received, isFalse);
    });

    testWidgets('en estado mixto se marca como mixta y al tocar entrega true', (
      tester,
    ) async {
      bool? received;
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        CascaCheckbox(
          value: null,
          semanticLabel: 'Todos',
          onChanged: (value) => received = value,
        ),
      );

      final semantics = tester.getSemantics(find.bySemanticsLabel('Todos'));
      expect(semantics.flagsCollection.isChecked, CheckedState.mixed);

      await tester.tap(find.bySemanticsLabel('Todos'));
      expect(received, isTrue);
      handle.dispose();
    });

    testWidgets('sin onChanged no responde', (tester) async {
      await _pump(
        tester,
        const CascaCheckbox(
          value: false,
          semanticLabel: 'Aceptar',
          onChanged: null,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Aceptar'));
    });
  });

  group('CascaStatusChip', () {
    testWidgets('muestra la etiqueta en cada tono', (tester) async {
      for (final tone in CascaChipTone.values) {
        await _pump(tester, CascaStatusChip(label: tone.name, tone: tone));

        expect(find.text(tone.name), findsOneWidget);
      }
    });
  });
}
