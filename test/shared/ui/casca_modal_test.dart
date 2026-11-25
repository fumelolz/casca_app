import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onOpen,
  double width = 1000,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: CascaTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onOpen(context),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Future<void> _openSimple(BuildContext context, {bool dismissible = true}) {
  return showCascaModal<void>(
    context: context,
    dismissible: dismissible,
    builder: (_) =>
        const CascaModal(title: 'Nueva categoría', child: Text('Contenido')),
  );
}

void main() {
  testWidgets('en pantalla ancha abre un cuadro centrado', (tester) async {
    await _pump(tester, onOpen: _openSimple);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Nueva categoría'), findsOneWidget);
    expect(find.text('Contenido'), findsOneWidget);
  });

  testWidgets('en móvil abre una hoja inferior', (tester) async {
    await _pump(tester, onOpen: _openSimple, width: 390);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('el botón cerrar cierra el modal', (tester) async {
    await _pump(tester, onOpen: _openSimple);

    await tester.tap(find.bySemanticsLabel('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Contenido'), findsNothing);
  });

  testWidgets('tocar fuera cierra el modal', (tester) async {
    await _pump(tester, onOpen: _openSimple);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Contenido'), findsNothing);
  });

  testWidgets('si no es descartable tocar fuera no lo cierra', (tester) async {
    await _pump(
      tester,
      onOpen: (context) => _openSimple(context, dismissible: false),
    );

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Contenido'), findsOneWidget);
  });

  group('showCascaConfirm', () {
    Future<List<bool>> open(WidgetTester tester, {double width = 1000}) async {
      final results = <bool>[];
      await _pump(
        tester,
        width: width,
        onOpen: (context) async {
          results.add(
            await showCascaConfirm(
              context: context,
              title: 'Eliminar categoría',
              message: '¿Seguro?',
              confirmLabel: 'Eliminar',
              danger: true,
            ),
          );
        },
      );
      return results;
    }

    testWidgets('confirmar devuelve true', (tester) async {
      final results = await open(tester);

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(results, [true]);
    });

    testWidgets('cancelar devuelve false', (tester) async {
      final results = await open(tester, width: 390);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(results, [false]);
    });

    testWidgets('cerrar sin elegir devuelve false', (tester) async {
      final results = await open(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(results, [false]);
    });
  });
}
