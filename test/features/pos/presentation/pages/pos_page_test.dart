import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/pos/presentation/pages/pos_page.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_scanner.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/fake_http_adapter.dart';
import '../../../../support/fake_auth_repository.dart';

Map<String, dynamic> _product(
  String id,
  String name, {
  double price = 100,
  double stock = 5,
  bool decimals = false,
}) => {
  'id': id,
  'productId': 'p-$id',
  'productVariantId': null,
  'sellableItemId': 'u-$id',
  'type': 0,
  'displayName': name,
  'price': price,
  'sku': id,
  'quantity': stock,
  'conversionFactor': 1,
  'allowsDecimalQuantity': decimals,
  'affectsInventory': true,
  'image': null,
};

Map<String, dynamic> _previewLine(Map item, String? salePriceListId) {
  final listId = item['priceListId'] ?? salePriceListId;
  final price = item['customPrice'] as num? ?? (listId == 'l1' ? 80 : 100);

  return {
    ...item.cast<String, dynamic>(),
    'unitPrice': price,
    'lineTotal': (item['quantity'] as num) * price,
  };
}

class _Server {
  bool shiftOpen = true;
  int failedSales = 0;
  final requests = <RequestOptions>[];

  List<RequestOptions> sent(String path) =>
      requests.where((r) => r.path == path).toList();

  Future<ResponseBody> handle(RequestOptions options) async {
    requests.add(options);
    final path = options.path;

    if (path.endsWith('/cash-registers/active')) {
      return shiftOpen
          ? jsonResponse({
              'data': {'id': 't1'},
            }, 200)
          : jsonResponse({
              'errors': [
                {
                  'code': 'CashRegister.NoActiveShift',
                  'description': 'Sin turno.',
                },
              ],
            }, 400);
    }
    if (path.endsWith('/pos/catalog')) {
      return jsonResponse({
        'data': {
          'items': [
            _product('a', 'Playera'),
            _product('b', 'Gorra', stock: 0),
            _product('c', 'Arroz', price: 30, decimals: true),
          ],
          'hasNextPage': false,
        },
      }, 200);
    }
    if (path.endsWith('/sales/preview')) {
      final body = options.data as Map;
      final lines = [
        for (final item in body['items'] as List)
          _previewLine(item as Map, body['priceListId'] as String?),
      ];
      final total = lines.fold<num>(
        0,
        (sum, line) => sum + (line['lineTotal'] as num),
      );
      return jsonResponse({
        'data': {'items': lines, 'subtotal': total, 'finalTotal': total},
      }, 200);
    }
    if (path.endsWith('/pos/catalog/exact')) {
      return switch (options.queryParameters['value']) {
        '750' => jsonResponse({'data': _product('a', 'Playera')}, 200),
        '751' => jsonResponse({'data': _product('b', 'Gorra', stock: 0)}, 200),
        _ => jsonResponse({'message': 'Producto no encontrado'}, 404),
      };
    }
    if (path.endsWith('/price-lists')) {
      return jsonResponse({
        'data': [
          {'id': 'l1', 'name': 'Mayorista'},
        ],
      }, 200);
    }
    if (failedSales > 0) {
      failedSales--;
      return jsonResponse({'message': 'Error interno'}, 500);
    }
    return jsonResponse({
      'data': {'id': 'v1', 'saleNumber': 'V-0001', 'totalAmount': 100},
    }, 200);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Server server, {
  double width = 1200,
  List<String> extraPermissions = const [],
  void Function(ValueChanged<String> detect)? onCamera,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(server.handle);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          hasSession: true,
          session: fullAccessSession(
            permissions: [...allPermissions, ...extraPermissions],
          ),
        ),
      ),
      apiClientProvider.overrideWithValue(ApiClient(dio, DefaultCookieJar())),
      barcodeCameraProvider.overrideWithValue((detect) {
        onCamera?.call(detect);
        return const Text('cámara');
      }),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.notifier).restoreSession();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: CascaTheme.light,
        home: const Scaffold(body: PosPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byKey(ValueKey('pos-item-$id'));

Finder _paymentInput(String label) => find.descendant(
  of: find.byKey(Key('payment-input-$label')),
  matching: find.byType(TextField),
);

void main() {
  testWidgets('agrega productos y muestra el total del servidor', (
    tester,
  ) async {
    final server = _Server();
    await _pump(tester, server);

    await _tap(tester, _card('a'));
    await _tap(tester, _card('a'));

    expect(find.text('Cobrar \$200.00'), findsOneWidget);
  });

  testWidgets('no agrega un producto agotado', (tester) async {
    await _pump(tester, _Server());

    await _tap(tester, _card('b'));

    expect(find.text('Tu venta está vacía'), findsOneWidget);
  });

  testWidgets('no pasa de las existencias', (tester) async {
    await _pump(tester, _Server());

    for (var i = 0; i < 6; i++) {
      await _tap(tester, _card('a'));
    }

    expect(find.text('Máximo disponible'), findsOneWidget);
    expect(find.text('Cobrar \$500.00'), findsOneWidget);
  });

  testWidgets('con una pieza el menos se vuelve quitar', (tester) async {
    await _pump(tester, _Server());
    await _tap(tester, _card('a'));
    await _tap(tester, _card('a'));

    await _tap(tester, find.bySemanticsLabel('Disminuir cantidad de Playera'));
    await _tap(tester, find.bySemanticsLabel('Quitar Playera'));

    expect(find.text('Tu venta está vacía'), findsOneWidget);
  });

  testWidgets('la cantidad escrita se limita a las existencias', (
    tester,
  ) async {
    await _pump(tester, _Server());
    await _tap(tester, _card('a'));
    final field = find.byType(TextField).last;

    await tester.enterText(field, '9');
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(field).controller!.text, '5');
    expect(find.text('Cobrar \$500.00'), findsOneWidget);
  });

  testWidgets('quita un producto desde su menú', (tester) async {
    await _pump(tester, _Server());
    await _tap(tester, _card('a'));
    await _tap(tester, _card('a'));

    await _tap(tester, find.bySemanticsLabel('Acciones de Playera'));
    await _tap(tester, find.text('Quitar'));

    expect(find.text('Tu venta está vacía'), findsOneWidget);
  });

  testWidgets('pide la cantidad de un producto a granel', (tester) async {
    await _pump(tester, _Server());

    await _tap(tester, _card('c'));
    await tester.enterText(find.byType(TextField).at(1), '1.5');
    await tester.pump();
    await _tap(tester, find.text('Agregar'));

    expect(find.text('Cobrar \$150.00'), findsOneWidget);
  });

  testWidgets('sin turno abierto no permite cobrar', (tester) async {
    await _pump(tester, _Server()..shiftOpen = false);
    await _tap(tester, _card('a'));

    await _tap(tester, find.text('Cobrar \$100.00'));

    expect(find.text('No hay un turno de caja abierto'), findsOneWidget);
    expect(find.text('Registrar Venta'), findsNothing);
  });

  testWidgets('cobra en efectivo, muestra el cambio y vacía la venta', (
    tester,
  ) async {
    final server = _Server();
    await _pump(tester, server);
    await _tap(tester, _card('a'));
    await _tap(tester, find.text('Cobrar \$100.00'));

    await tester.enterText(_paymentInput('Efectivo recibido'), '500');
    await tester.pump();
    await _tap(tester, find.text('Recibir'));

    expect(find.text('¡Venta registrada!'), findsOneWidget);
    expect(find.text('\$400.00'), findsOneWidget);
    final sale = server.sent('/api/v1/sales').single;
    expect(sale.headers['Idempotency-Key'], hasLength(32));
    expect((sale.data as Map)['payments'], [
      {'method': 0, 'amount': 100, 'cashReceived': 500},
    ]);

    await _tap(tester, find.text('Nueva venta'));
    expect(find.text('Tu venta está vacía'), findsOneWidget);
  });

  testWidgets('reintentar el mismo pago repite la clave', (tester) async {
    final server = _Server()..failedSales = 1;
    await _pump(tester, server);
    await _tap(tester, _card('a'));
    await _tap(tester, find.text('Cobrar \$100.00'));
    await _tap(tester, find.text('Transferencia'));

    await _tap(tester, find.text('Cobrar \$100.00').last);
    expect(find.textContaining('no se duplicará'), findsOneWidget);
    await _tap(tester, find.text('Cobrar \$100.00').last);

    final keys = [
      for (final sale in server.sent('/api/v1/sales'))
        sale.headers['Idempotency-Key'],
    ];
    expect(keys, hasLength(2));
    expect(keys.first, keys.last);
    expect(find.text('¡Venta registrada!'), findsOneWidget);
  });

  testWidgets('divide el pago entre efectivo y tarjeta', (tester) async {
    final server = _Server();
    await _pump(tester, server);
    await _tap(tester, _card('a'));
    await _tap(tester, find.text('Cobrar \$100.00'));
    await _tap(tester, find.text('Usar Múltiples Métodos'));

    await tester.enterText(_paymentInput('Efectivo'), '60');
    await tester.enterText(_paymentInput('Tarjeta de Débito'), '40');
    await tester.pump();
    await _tap(tester, find.text('Cobrar').last);

    final sale = server.sent('/api/v1/sales').single.data as Map;
    expect(sale['payments'], [
      {'method': 0, 'amount': 60, 'cashReceived': 60},
      {'method': 3, 'amount': 40},
    ]);
  });

  group('códigos', () {
    Future<void> submit(WidgetTester tester, String code) async {
      await tester.enterText(find.byType(TextField).first, code);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
    }

    testWidgets('Enter agrega el producto y limpia el buscador', (
      tester,
    ) async {
      await _pump(tester, _Server());

      await submit(tester, '750');

      expect(find.text('Cobrar \$100.00'), findsOneWidget);
      final search = tester.widget<TextField>(find.byType(TextField).first);
      expect(search.controller!.text, isEmpty);
      expect(search.focusNode!.hasFocus, isTrue);
    });

    testWidgets('Enter con un producto agotado lo avisa', (tester) async {
      await _pump(tester, _Server());

      await submit(tester, '751');

      expect(find.text('Gorra está agotado.'), findsOneWidget);
    });

    testWidgets('la cámara agrega sin repetir la misma lectura', (
      tester,
    ) async {
      late ValueChanged<String> detect;
      await _pump(tester, _Server(), onCamera: (value) => detect = value);
      await _tap(tester, find.bySemanticsLabel('Escanear código de barras'));

      detect('750');
      await tester.pump(const Duration(milliseconds: 100));
      detect('750');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(find.text('Agregado: Playera'), findsOneWidget);
      expect(find.text('1 producto · \$100.00'), findsOneWidget);

      await tester.pump(repeatDelay);
      detect('750');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(find.text('1 producto · \$200.00'), findsOneWidget);
      await tester.pump(repeatDelay);
    });

    testWidgets('la cámara avisa si el código no existe', (tester) async {
      late ValueChanged<String> detect;
      await _pump(
        tester,
        _Server(),
        width: 360,
        onCamera: (value) => detect = value,
      );
      await _tap(tester, find.bySemanticsLabel('Escanear código de barras'));

      detect('999');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(
        find.text('No hay un producto con el código 999.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(repeatDelay);
    });
  });

  group('precios', () {
    const permissions = ['sale.applypricelist', 'sale.customprice'];

    Future<void> openPrice(WidgetTester tester) {
      return _tap(tester, find.bySemanticsLabel('Cambiar precio de Playera'));
    }

    testWidgets('la lista de la venta cambia catálogo, total y cobro', (
      tester,
    ) async {
      final server = _Server();
      await _pump(tester, server, extraPermissions: permissions);
      await _tap(tester, _card('a'));

      await _tap(tester, find.text('Público'));
      await _tap(tester, find.text('Mayorista'));
      await _tap(tester, find.text('Cambiar lista'));

      expect(find.text('Cobrar \$80.00'), findsOneWidget);
      expect(
        server.sent('/api/v1/pos/catalog').last.queryParameters['priceListId'],
        'l1',
      );

      await _tap(tester, find.text('Cobrar \$80.00'));
      await _tap(tester, find.text('Transferencia'));
      await _tap(tester, find.text('Cobrar \$80.00').last);

      final sale = server.sent('/api/v1/sales').single.data as Map;
      expect(sale['priceListId'], 'l1');
      await _tap(tester, find.text('Nueva venta'));
      expect(find.text('Público'), findsOneWidget);
    });

    testWidgets('un producto puede usar su propia lista', (tester) async {
      final server = _Server();
      await _pump(tester, server, extraPermissions: permissions);
      await _tap(tester, _card('a'));

      await openPrice(tester);
      await _tap(tester, find.text('Público').last);
      await _tap(tester, find.text('Mayorista').last);
      expect(find.text('\$80.00'), findsOneWidget);
      await _tap(tester, find.text('Aplicar'));

      expect(find.text('Cobrar \$80.00'), findsOneWidget);
      expect(find.textContaining('· Mayorista'), findsOneWidget);
      final preview = server.sent('/api/v1/sales/preview').last.data as Map;
      expect(preview['priceListId'], isNull);
      expect(
        (preview['items'] as List).single,
        containsPair('priceListId', 'l1'),
      );
    });

    testWidgets('el precio personalizado se conserva al agregar otro', (
      tester,
    ) async {
      final server = _Server();
      await _pump(tester, server, extraPermissions: permissions);
      await _tap(tester, _card('a'));

      await openPrice(tester);
      await tester.enterText(find.byType(TextField).last, '70');
      await _tap(tester, find.text('Aplicar'));
      await _tap(tester, _card('a'));

      expect(find.textContaining('· Personalizado'), findsOneWidget);
      expect(find.text('Cobrar \$140.00'), findsOneWidget);
    });

    testWidgets('sin permisos no permite cambiar precios', (tester) async {
      final server = _Server();
      await _pump(tester, server);
      await _tap(tester, _card('a'));

      expect(find.bySemanticsLabel('Cambiar precio de Playera'), findsNothing);
      expect(find.text('Lista de precios'), findsNothing);
      expect(server.sent('/api/v1/price-lists'), isEmpty);
    });

    testWidgets('en teléfono cambia el precio desde la venta', (tester) async {
      await _pump(tester, _Server(), width: 360, extraPermissions: permissions);
      await _tap(tester, _card('a'));
      await _tap(tester, find.textContaining('Ver venta'));

      await openPrice(tester);

      expect(find.text('Precio del producto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('en teléfono abre la venta y cobra sin desbordar', (
    tester,
  ) async {
    await _pump(tester, _Server(), width: 360);
    await _tap(tester, _card('a'));
    await _tap(tester, find.textContaining('Ver venta'));

    expect(find.text('Playera'), findsWidgets);
    await _tap(tester, find.text('Cobrar \$100.00'));
    expect(find.text('Registrar Venta'), findsOneWidget);
    await _tap(tester, find.text('Usar Múltiples Métodos'));

    expect(tester.takeException(), isNull);
  });
}
