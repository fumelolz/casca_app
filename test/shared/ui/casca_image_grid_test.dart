import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_image_grid.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CascaImageItem _item(String id) {
  return CascaImageItem(
    id: id,
    child: Text('mini $id'),
    preview: Text('grande $id'),
    actions: [
      CascaActionMenuItem(id: 'x', label: 'Quitar $id', onSelected: () {}),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  List<String> ids = const ['a', 'b', 'c'],
  bool loading = false,
  double width = 390,
  VoidCallback? onAdd,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: CascaTheme.light,
      home: Scaffold(
        body: CascaImageGrid(
          main: ids.isEmpty ? null : _item(ids.first),
          secondary: [for (final id in ids.skip(1)) _item(id)],
          loading: loading,
          onAdd: onAdd ?? () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _swipe(WidgetTester tester) async {
  await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('en escritorio la principal va junto a dos filas de tres', (
    tester,
  ) async {
    await _pump(tester, ids: [for (var i = 0; i < 7; i++) '$i'], width: 1000);

    expect(find.byType(PageView), findsNothing);
    Rect tile(int i) => tester.getRect(
      find.ancestor(
        of: i == 0 ? find.text('grande 0') : find.text('mini $i'),
        matching: find.byType(CascaActionMenu),
      ),
    );
    expect(tile(1).top, tile(0).top);
    expect(tile(3).top, tile(0).top);
    expect(tile(4).left, tile(1).left);
    expect(tile(6).bottom, closeTo(tile(0).bottom, 0.01));
    expect(tile(6).right, closeTo(720, 0.01));
    expect(find.bySemanticsLabel('Agregar imagen'), findsNothing);
  });

  testWidgets('en escritorio marca los espacios libres', (tester) async {
    await _pump(tester, ids: ['a', 'b'], width: 1000);

    expect(find.bySemanticsLabel('Agregar imagen'), findsOneWidget);
    for (final index in [2, 3, 4, 5]) {
      expect(find.byKey(ValueKey('image-slot-empty-$index')), findsOneWidget);
    }
  });

  for (final width in [390.0, 1000.0]) {
    testWidgets('mientras carga no invita a agregar la foto ($width)', (
      tester,
    ) async {
      await _pump(tester, ids: [], loading: true, width: width);

      expect(find.text('Agregar foto'), findsNothing);
      expect(find.byType(CascaSkeleton), findsWidgets);
    });
  }

  testWidgets('en el ancho intermedio no desborda', (tester) async {
    await _pump(tester, width: 480 + 300);

    expect(tester.takeException(), isNull);
  });

  testWidgets('en móvil muestra una imagen grande a la vez', (tester) async {
    await _pump(tester);

    expect(find.text('grande a'), findsOneWidget);
    expect(find.text('grande b'), findsNothing);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('image-viewer'))).height, 360);
  });

  testWidgets('al deslizar pasa a la siguiente', (tester) async {
    await _pump(tester);

    await _swipe(tester);

    expect(find.text('grande b'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('Principal'), findsNothing);
  });

  testWidgets('al tocar una miniatura muestra esa imagen', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('mini c'));
    await tester.pumpAndSettle();

    expect(find.text('grande c'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('las opciones son las de la imagen visible', (tester) async {
    await _pump(tester);
    await _swipe(tester);

    await tester.tap(find.byType(CascaActionMenu));
    await tester.pumpAndSettle();

    expect(find.text('Quitar b'), findsOneWidget);
    expect(find.text('Quitar a'), findsNothing);
  });

  testWidgets('al agregar una imagen la muestra', (tester) async {
    await _pump(tester, ids: ['a', 'b']);

    await _pump(tester, ids: ['a', 'b', 'c']);
    await tester.pumpAndSettle();

    expect(find.text('grande c'), findsOneWidget);
  });

  testWidgets('al llegar la galería se queda en la principal', (tester) async {
    await _pump(tester, ids: ['a'], loading: true);

    await _pump(tester, ids: ['a', 'b', 'c']);
    await tester.pumpAndSettle();

    expect(find.text('grande a'), findsOneWidget);
  });

  testWidgets('al borrar la última visible muestra la anterior', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('mini c'));
    await tester.pumpAndSettle();

    await _pump(tester, ids: ['a', 'b']);
    await tester.pumpAndSettle();

    expect(find.text('grande b'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('sigue a la imagen que pasa a ser principal', (tester) async {
    await _pump(tester);
    await _swipe(tester);

    await _pump(tester, ids: ['b', 'a', 'c']);
    await tester.pumpAndSettle();

    expect(find.text('grande b'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
  });

  testWidgets('sin imágenes ofrece agregar la primera', (tester) async {
    var taps = 0;
    await _pump(tester, ids: [], onAdd: () => taps++);

    await tester.tap(find.text('Agregar foto'));

    expect(taps, 1);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('muchas imágenes no desbordan un teléfono angosto', (
    tester,
  ) async {
    await _pump(tester, ids: [for (var i = 0; i < 7; i++) '$i'], width: 320);

    for (var i = 0; i < 6; i++) {
      await _swipe(tester);
    }

    expect(tester.takeException(), isNull);
    expect(find.text('7 / 7'), findsOneWidget);
    expect(tester.getRect(find.text('mini 6')).right, lessThanOrEqualTo(320));
  });
}
