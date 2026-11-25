import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Item {
  const _Item(this.id, this.name, this.detail, this.stock);

  final String id;
  final String name;
  final String detail;
  final int stock;
}

const _items = [
  _Item('1', 'Café Brasil', 'Granos', 2),
  _Item('2', 'Té Assam', 'Hojas', 6),
  _Item('3', 'Cacao', 'Polvo', 3),
];

final _columns = [
  CascaTableColumn<_Item>(
    id: 'name',
    header: 'Nombre',
    flex: 3,
    sortable: true,
    showOnCompact: true,
    cellBuilder: (context, row) => Text(row.name),
  ),
  CascaTableColumn<_Item>(
    id: 'detail',
    header: 'Detalle',
    cellBuilder: (context, row) => Text(row.detail),
  ),
  CascaTableColumn<_Item>(
    id: 'stock',
    header: 'Stock',
    width: 80,
    align: CascaTableAlign.end,
    showOnCompact: true,
    cellBuilder: (context, row) => Text('${row.stock}'),
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required Widget table,
  double width = 900,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: CascaTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: table)),
    ),
  );
}

CascaTable<_Item> _table({
  List<_Item> rows = _items,
  bool loading = false,
  String? errorMessage,
  VoidCallback? onRetry,
  Set<String>? selectedKeys,
  ValueChanged<Set<String>>? onSelectionChanged,
  CascaTableSort? sort,
  ValueChanged<CascaTableSort?>? onSortChanged,
  List<CascaTableRowAction<_Item>> rowActions = const [],
  List<CascaTableBulkAction> bulkActions = const [],
  int page = 1,
  int pageSize = 10,
  int? totalItems,
  ValueChanged<int>? onPageChanged,
}) {
  return CascaTable<_Item>(
    columns: _columns,
    rows: rows,
    rowKey: (row) => row.id,
    loading: loading,
    errorMessage: errorMessage,
    onRetry: onRetry,
    selectedKeys: selectedKeys,
    onSelectionChanged: onSelectionChanged,
    sort: sort,
    onSortChanged: onSortChanged,
    rowActions: rowActions,
    bulkActions: bulkActions,
    page: page,
    pageSize: pageSize,
    totalItems: totalItems,
    onPageChanged: onPageChanged,
  );
}

void main() {
  group('columnas', () {
    testWidgets('en pantalla ancha muestra todas las columnas', (tester) async {
      await _pump(tester, table: _table());

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Detalle'), findsOneWidget);
      expect(find.text('Stock'), findsOneWidget);
      expect(find.text('Café Brasil'), findsOneWidget);
      expect(find.text('Granos'), findsOneWidget);
    });

    testWidgets('en pantalla angosta solo muestra las columnas compactas', (
      tester,
    ) async {
      await _pump(tester, table: _table(), width: 400);

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Stock'), findsOneWidget);
      expect(find.text('Detalle'), findsNothing);
      expect(find.text('Granos'), findsNothing);
    });
  });

  group('selección', () {
    testWidgets('la casilla del encabezado selecciona todas las filas', (
      tester,
    ) async {
      Set<String>? result;
      await _pump(
        tester,
        table: _table(
          selectedKeys: const {},
          onSelectionChanged: (keys) => result = keys,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Seleccionar todos'));

      expect(result, {'1', '2', '3'});
    });

    testWidgets('con selección parcial la casilla del encabezado completa', (
      tester,
    ) async {
      Set<String>? result;
      await _pump(
        tester,
        table: _table(
          selectedKeys: const {'1'},
          onSelectionChanged: (keys) => result = keys,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Seleccionar todos'));

      expect(result, {'1', '2', '3'});
    });

    testWidgets('con todo seleccionado la casilla del encabezado limpia', (
      tester,
    ) async {
      Set<String>? result;
      await _pump(
        tester,
        table: _table(
          selectedKeys: const {'1', '2', '3'},
          onSelectionChanged: (keys) => result = keys,
        ),
      );

      await tester.tap(find.bySemanticsLabel('Seleccionar todos'));

      expect(result, isEmpty);
    });

    testWidgets('la casilla de una fila agrega y quita su clave', (
      tester,
    ) async {
      Set<String>? result;
      await _pump(
        tester,
        table: _table(
          selectedKeys: const {'2'},
          onSelectionChanged: (keys) => result = keys,
        ),
      );

      await tester.tap(find.byType(CascaCheckbox).at(1));
      expect(result, {'1', '2'});

      await tester.tap(find.byType(CascaCheckbox).at(2));
      expect(result, isEmpty);
    });

    testWidgets('sin selectedKeys no muestra casillas', (tester) async {
      await _pump(tester, table: _table());

      expect(find.bySemanticsLabel('Seleccionar todos'), findsNothing);
    });
  });

  group('orden', () {
    testWidgets('recorre ascendente, descendente y sin orden', (tester) async {
      final results = <CascaTableSort?>[];

      Future<void> tapName(CascaTableSort? current) async {
        await _pump(
          tester,
          table: _table(sort: current, onSortChanged: results.add),
        );
        await tester.tap(find.text('Nombre'));
      }

      await tapName(null);
      await tapName(const CascaTableSort('name', CascaSortDirection.asc));
      await tapName(const CascaTableSort('name', CascaSortDirection.desc));

      expect(results[0]?.direction, CascaSortDirection.asc);
      expect(results[1]?.direction, CascaSortDirection.desc);
      expect(results[2], isNull);
    });

    testWidgets('una columna no ordenable no responde al toque', (
      tester,
    ) async {
      var calls = 0;
      await _pump(tester, table: _table(onSortChanged: (_) => calls++));

      await tester.tap(find.text('Detalle'));

      expect(calls, 0);
    });
  });

  group('paginación', () {
    testWidgets('muestra el rango y avanza a la página siguiente', (
      tester,
    ) async {
      int? requested;
      await _pump(
        tester,
        table: _table(
          page: 2,
          pageSize: 10,
          totalItems: 25,
          onPageChanged: (page) => requested = page,
        ),
      );

      expect(find.text('11–20 de 25'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Página siguiente'));
      expect(requested, 3);

      await tester.tap(find.bySemanticsLabel('Página anterior'));
      expect(requested, 1);
    });

    testWidgets('en la primera página no se puede retroceder', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        table: _table(totalItems: 25, onPageChanged: (_) => calls++),
      );

      await tester.tap(find.bySemanticsLabel('Página anterior'));

      expect(calls, 0);
    });

    testWidgets('en la última página no se puede avanzar', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        table: _table(page: 3, totalItems: 25, onPageChanged: (_) => calls++),
      );

      expect(find.text('21–25 de 25'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Página siguiente'));

      expect(calls, 0);
    });
  });

  group('estados', () {
    testWidgets('cargando sin datos muestra el esqueleto', (tester) async {
      await _pump(tester, table: _table(rows: const [], loading: true));

      expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
      expect(find.text('Sin registros'), findsNothing);
    });

    testWidgets('sin datos muestra el mensaje de vacío', (tester) async {
      await _pump(tester, table: _table(rows: const []));

      expect(find.text('Sin registros'), findsOneWidget);
    });

    testWidgets('con error muestra el mensaje y permite reintentar', (
      tester,
    ) async {
      var retries = 0;
      await _pump(
        tester,
        table: _table(
          errorMessage: 'No fue posible cargar.',
          onRetry: () => retries++,
        ),
      );

      expect(find.text('No fue posible cargar.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));

      expect(retries, 1);
    });

    testWidgets('al cambiar de página conserva las filas mientras carga', (
      tester,
    ) async {
      await _pump(tester, table: _table(loading: true));

      expect(find.text('Café Brasil'), findsOneWidget);
    });
  });

  group('acciones', () {
    testWidgets('el menú de la fila ejecuta la acción con su fila', (
      tester,
    ) async {
      _Item? received;
      await _pump(
        tester,
        table: _table(
          rowActions: [
            CascaTableRowAction<_Item>(
              label: 'Editar',
              onSelected: (row) => received = row,
            ),
          ],
        ),
      );

      await tester.tap(find.byType(CascaActionMenu).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(received?.id, '2');
    });

    testWidgets('la barra de acciones aparece con selección y ejecuta', (
      tester,
    ) async {
      var deactivated = 0;
      await _pump(
        tester,
        table: _table(
          selectedKeys: const {'1', '3'},
          onSelectionChanged: (_) {},
          bulkActions: [
            CascaTableBulkAction(
              label: 'Desactivar',
              danger: true,
              onPressed: () => deactivated++,
            ),
          ],
        ),
      );

      expect(find.text('2 seleccionados'), findsOneWidget);
      await tester.tap(find.text('Desactivar'));

      expect(deactivated, 1);
    });

    testWidgets('sin selección no aparece la barra de acciones', (
      tester,
    ) async {
      await _pump(
        tester,
        table: _table(
          selectedKeys: const {},
          onSelectionChanged: (_) {},
          bulkActions: [
            CascaTableBulkAction(label: 'Desactivar', onPressed: () {}),
          ],
        ),
      );

      expect(find.text('Desactivar'), findsNothing);
    });

    testWidgets('sin barra de acciones el pie cuenta las seleccionadas', (
      tester,
    ) async {
      await _pump(
        tester,
        table: _table(
          selectedKeys: const {'1', '2', '3'},
          onSelectionChanged: (_) {},
        ),
      );

      expect(find.text('3 seleccionados'), findsOneWidget);
    });
  });
}
