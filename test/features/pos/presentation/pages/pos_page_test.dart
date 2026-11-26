import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/pos/presentation/pages/pos_page.dart';
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
      final items = (options.data as Map)['items'] as List;
      final total = items.fold<double>(
        0,
        (sum, item) => sum + ((item as Map)['quantity'] as num) * 100,
      );
      return jsonResponse({
        'data': {
          'items': [
            for (final item in items)
              {
                ...(item as Map).cast<String, dynamic>(),
                'unitPrice': 100,
                'lineTotal': (item['quantity'] as num) * 100,
              },
          ],
          'subtotal': total,
          'finalTotal': total,
        },
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
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(server.handle);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(hasSession: true, session: fullAccessSession()),
      ),
      apiClientProvider.overrideWithValue(ApiClient(dio, DefaultCookieJar())),
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

    expect(find.textContaining('Solo hay 5 disponible'), findsOneWidget);
    expect(find.text('Cobrar \$500.00'), findsOneWidget);
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
