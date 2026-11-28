import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/products/data/product_endpoints.dart';
import 'package:casca_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_fields.dart';
import 'package:casca_app/features/products/presentation/widgets/product_thumbnail.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/fake_http_adapter.dart';
import '../../../../support/fake_auth_repository.dart';

const _editor = [
  ...allPermissions,
  'inventory.update',
  'product.update',
  'product.delete',
];

Map<String, dynamic> _variant(String id, String size, int position) => {
  'id': id,
  'sku': 'SKU-$size',
  'displayName': size,
  'status': 1,
  'minimumStock': 1,
  'maximumStock': null,
  'stock': 4,
  'options': [
    {
      'name': 'Talla',
      'value': size,
      'optionPosition': 0,
      'valuePosition': position,
    },
  ],
  'saleUnits': [
    {
      'id': 'u-$id',
      'displayName': 'Pieza',
      'unitOfMeasure': 0,
      'conversionFactor': 1,
      'price': 10,
      'affectsInventory': true,
      'allowsDecimalQuantity': false,
      'isInventoryBaseUnit': true,
      'barcode': null,
    },
  ],
};

Map<String, dynamic> _detail({bool variants = false}) => {
  'id': 'p1',
  'name': 'Arroz',
  'sku': 'ARZ-1',
  'description': 'Grano largo',
  'category': {'id': 'c1', 'name': 'Abarrotes'},
  'productType': 0,
  'version': 3,
  'isActive': true,
  'defaultTaxRate': 2,
  'defaultIepsTaxRate': 0,
  'satUnitCode': 3,
  'minimumStock': 5,
  'maximumStock': 50,
  'averageCost': 12.5,
  'stock': 20,
  'image': {'webpThumbnailUrl': '/images/main.webp'},
  'variants': variants
      ? [_variant('v1', 'CH', 0), _variant('v2', 'M', 1)]
      : <Object>[],
  'saleUnits': [
    {
      'unitOfMeasure': 1,
      'barcode': '750',
      'price': 18,
      'cost': 0,
      'isInventoryBaseUnit': true,
      'allowsDecimalQuantity': false,
    },
  ],
};

Map<String, dynamic> _movement(String name, double quantity, int reason) => {
  'displayName': name,
  'movementType': quantity > 0 ? 0 : 1,
  'quantity': quantity,
  'unitCost': 12.5,
  'totalCost': quantity * 12.5,
  'reason': reason,
  'createdOnUtc': '2026-11-20T18:30:00Z',
};

class _Server {
  _Server({this.variants = false});

  final bool variants;
  final requests = <RequestOptions>[];
  int writeStatus = 200;
  int movementPages = 1;

  Iterable<RequestOptions> sent(String method) =>
      requests.where((request) => request.method == method);

  Future<ResponseBody> handle(RequestOptions options) async {
    requests.add(options);
    if (options.method != 'GET') {
      return jsonResponse({
        'data': null,
        if (writeStatus >= 400) 'message': 'El producto tiene existencias.',
      }, writeStatus);
    }
    if (options.path == ProductEndpoints.gallery('p1')) {
      return jsonResponse({
        'data': [
          {
            'id': 'g1',
            'image': {'webpThumbnailUrl': '/images/g1.webp'},
            'sortOrder': 0,
          },
        ],
      }, 200);
    }
    if (options.path == ProductEndpoints.movements('p1')) {
      final page = options.queryParameters['page'] as int;
      return jsonResponse({
        'data': {
          'items': [
            if (page == 1)
              _movement(variants ? 'Arroz CH' : 'Arroz', 10, 0)
            else
              _movement('Arroz', -2, 3),
          ],
          'page': page,
          'pageSize': 10,
          'totalCount': movementPages,
          'totalPages': movementPages,
          'hasNextPage': page < movementPages,
          'hasPreviousPage': page > 1,
        },
      }, 200);
    }
    return jsonResponse({'data': _detail(variants: variants)}, 200);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Server server, {
  List<String> permissions = _editor,
  double width = 1200,
}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(server.handle);
  final router = GoRouter(
    initialLocation: '/detail',
    routes: [
      GoRoute(
        path: '/detail',
        builder: (_, _) =>
            const Scaffold(body: ProductDetailPage(productId: 'p1')),
      ),
      GoRoute(
        path: AppRoutes.products,
        builder: (_, _) => const Text('lista de productos'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio, DefaultCookieJar())),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            hasSession: true,
            session: fullAccessSession(permissions: permissions),
          ),
        ),
      ],
      child: MaterialApp.router(theme: CascaTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, String label, String text) {
  return tester.enterText(
    find.descendant(
      of: find.widgetWithText(ProductField, label),
      matching: find.byType(TextField),
    ),
    text,
  );
}

void main() {
  testWidgets('muestra resumen, galería y movimientos', (tester) async {
    final server = _Server();
    await _pump(tester, server);

    expect(find.text('Arroz'), findsOneWidget);
    expect(find.text('Categoría Abarrotes'), findsOneWidget);
    expect(
      find.text('SKU ARZ-1   ·   Cód. de barras 750'),
      findsOneWidget,
    );
    expect(find.text(r'$18.00'), findsOneWidget);
    expect(find.text('IVA 0%'), findsOneWidget);
    expect(find.text('Bajo'), findsOneWidget);
    expect(find.text(r'$12.50'), findsOneWidget);
    expect(find.text(r'$5.50'), findsOneWidget);
    expect(find.text('Margen 31%'), findsOneWidget);
    expect(find.text('Nuevo stock'), findsOneWidget);
    expect(find.byType(ProductPicture), findsNWidgets(3));
    expect(find.text('Compra'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
    expect(
      server
          .sent('GET')
          .where((r) => r.path == ProductEndpoints.movements('p1'))
          .single
          .queryParameters,
      {'sort': 'createdon', 'sortOrder': 'desc', 'page': 1, 'pageSize': 10},
    );
  });

  testWidgets('carga más movimientos', (tester) async {
    final server = _Server()..movementPages = 2;
    await _pump(tester, server);

    await _tapText(tester, 'Ver más movimientos');

    expect(find.text('Merma'), findsOneWidget);
    expect(find.text('-2'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Ver más movimientos'), findsNothing);
  });

  testWidgets('registra una salida y recarga el detalle', (tester) async {
    final server = _Server();
    await _pump(tester, server);

    await _tapText(tester, 'Ajustar existencias');
    await _tapText(tester, 'Salida');
    await _fill(tester, 'Cantidad', '25');
    await _tapText(tester, 'Guardar');

    expect(
      find.text('La cantidad supera la existencia actual'),
      findsOneWidget,
    );
    expect(server.sent('POST'), isEmpty);

    await _fill(tester, 'Cantidad', '3');
    await tester.pump();
    expect(find.text('Existencia después del ajuste: 17'), findsOneWidget);
    final gets = server.sent('GET').length;
    await _tapText(tester, 'Guardar');

    final post = server.sent('POST').single;
    expect(post.path, ProductEndpoints.movements('p1'));
    expect(post.data, {
      'type': 1,
      'quantity': 3.0,
      'unitCost': null,
      'reason': 3,
    });
    expect(find.text('Guardar'), findsNothing);
    expect(server.sent('GET').length, greaterThan(gets));
  });

  testWidgets('una compra exige el costo unitario', (tester) async {
    final server = _Server();
    await _pump(tester, server);

    await _tapText(tester, 'Ajustar existencias');
    await _fill(tester, 'Cantidad', '5');
    await _tapText(tester, 'Guardar');

    expect(find.text('Ingresa el costo unitario'), findsOneWidget);

    await _fill(tester, 'Costo unitario', '11');
    await _tapText(tester, 'Guardar');

    expect(server.sent('POST').single.data, {
      'type': 0,
      'quantity': 5.0,
      'unitCost': 11.0,
      'reason': 0,
    });
  });

  testWidgets('ajusta una variante desde su menú', (tester) async {
    final server = _Server(variants: true);
    await _pump(tester, server);

    expect(find.text('Variantes'), findsNWidgets(2));
    expect(find.text('Nuevo stock'), findsNothing);
    expect(find.text('Compra  ·  CH', findRichText: true), findsOneWidget);

    await tester.tap(find.byType(CascaActionMenu).at(1));
    await tester.pumpAndSettle();
    await _tapText(tester, 'Ajustar existencias');
    expect(find.text('Arroz · CH'), findsOneWidget);
    await _tapText(tester, 'Salida');
    await _fill(tester, 'Cantidad', '1');
    await _tapText(tester, 'Guardar');

    expect(
      server.sent('POST').single.path,
      ProductEndpoints.variantMovements('p1', 'v1'),
    );
  });

  testWidgets('sin permiso de inventario no ofrece el ajuste', (tester) async {
    await _pump(tester, _Server(), permissions: allPermissions);

    expect(find.text('Ajustar existencias'), findsNothing);
    await tester.tap(find.byType(CascaActionMenu).first);
    await tester.pumpAndSettle();
    expect(find.text('Imprimir etiquetas'), findsOneWidget);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Eliminar'), findsNothing);
  });

  testWidgets('elimina con la versión y vuelve a la lista', (tester) async {
    final server = _Server();
    await _pump(tester, server);

    await tester.tap(find.byType(CascaActionMenu).first);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Eliminar');
    await _tapText(tester, 'Eliminar');

    final delete = server.sent('DELETE').single;
    expect(delete.path, ProductEndpoints.byId('p1'));
    expect(delete.queryParameters, {'version': 3});
    expect(find.text('lista de productos'), findsOneWidget);
  });

  testWidgets('si no se puede eliminar muestra el motivo', (tester) async {
    final server = _Server()..writeStatus = 409;
    await _pump(tester, server);

    await tester.tap(find.byType(CascaActionMenu).first);
    await tester.pumpAndSettle();
    await _tapText(tester, 'Eliminar');
    await _tapText(tester, 'Eliminar');

    expect(find.text('El producto tiene existencias.'), findsOneWidget);
    expect(find.text('lista de productos'), findsNothing);
  });

  testWidgets('en teléfono no desborda', (tester) async {
    await _pump(tester, _Server(variants: true), width: 360);

    expect(tester.takeException(), isNull);
  });
}
