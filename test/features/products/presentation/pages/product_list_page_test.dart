import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/products/data/product_endpoints.dart';
import 'package:casca_app/features/products/presentation/pages/product_list_page.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
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
  int productType = 0,
  bool hasVariants = false,
}) => {
  'id': id,
  'name': name,
  'sku': 'SKU-$id',
  'barcode': null,
  'price': 18,
  'image': null,
  'isActive': true,
  'stock': 80,
  'minimumStock': 5,
  'maximumStock': 100,
  'averageCost': 15,
  'totalCost': 1200,
  'productType': productType,
  'hasVariants': hasVariants,
  'maxPrice': hasVariants ? 25 : null,
  'variantCount': hasVariants ? 3 : 0,
};

Future<List<RequestOptions>> _pump(
  WidgetTester tester, {
  double width = 1200,
  List<Map<String, dynamic>>? items,
  int status = 200,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter((options) async {
      requests.add(options);
      final list =
          items ??
          [
            _product('1', 'Arroz integral de grano largo'),
            _product('2', 'Playera', hasVariants: true),
            _product('3', 'Instalación', productType: 1),
          ];
      return jsonResponse({
        'data': {
          'items': list,
          'page': 1,
          'pageSize': 10,
          'totalCount': list.length,
          'totalPages': 1,
          'hasNextPage': false,
          'hasPreviousPage': false,
        },
      }, status);
    });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        apiClientProvider.overrideWithValue(ApiClient(dio, DefaultCookieJar())),
      ],
      child: MaterialApp(
        theme: CascaTheme.light,
        home: const Scaffold(body: ProductListPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

void main() {
  testWidgets('pide los más recientes y muestra precio, margen y stock', (
    tester,
  ) async {
    final requests = await _pump(tester);

    expect(requests.single.path, ProductEndpoints.list);
    expect(requests.single.queryParameters, {
      'sort': 'created',
      'order': 'desc',
      'page': 1,
      'pageSize': 10,
    });
    expect(find.text(r'+$3.00 (17%)'), findsNWidgets(2));
    expect(find.text(r'$18.00 – $25.00'), findsOneWidget);
    expect(find.text('SKU-2 · 3 variantes'), findsOneWidget);
    expect(find.text('Óptimo (80%)'), findsNWidgets(2));
  });

  testWidgets('en teléfono muestra solo producto y stock sin desbordar', (
    tester,
  ) async {
    await _pump(tester, width: 360);

    expect(find.text('Producto'), findsOneWidget);
    expect(find.text('Stock'), findsOneWidget);
    expect(find.text('Precio de venta'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en teléfono selecciona varios productos para etiquetas', (
    tester,
  ) async {
    await _pump(tester, width: 360);

    await tester.tap(find.byType(CascaCheckbox).first);
    await tester.pumpAndSettle();

    expect(find.text('3 seleccionados'), findsOneWidget);
    expect(find.text('Imprimir'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Quitar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    expect(find.text('3 seleccionados'), findsNothing);
  });

  testWidgets('ordena por stock y vuelve a los recientes', (tester) async {
    final requests = await _pump(tester);

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['sort'], 'stock');
    expect(requests.last.queryParameters['order'], 'asc');

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['order'], 'desc');

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    expect(requests.last.queryParameters['sort'], 'created');
  });

  testWidgets('buscar envía q después de la pausa', (tester) async {
    final requests = await _pump(tester);

    await tester.enterText(find.byType(TextField), 'arroz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(requests.last.queryParameters['q'], 'arroz');
  });

  testWidgets('sin productos muestra el mensaje de vacío', (tester) async {
    await _pump(tester, items: const []);

    expect(find.text('No existen productos.'), findsOneWidget);
  });

  testWidgets('con error permite reintentar', (tester) async {
    final requests = await _pump(tester, status: 500);

    expect(find.text('No fue posible obtener los productos.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(requests, hasLength(2));
  });
}
