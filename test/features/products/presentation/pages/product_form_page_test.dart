import 'dart:convert';

import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/products/data/category_endpoints.dart';
import 'package:casca_app/features/products/data/photo_picker.dart';
import 'package:casca_app/features/products/data/product_endpoints.dart';
import 'package:casca_app/features/products/presentation/pages/product_form_page.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_fields.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/network/fake_http_adapter.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _FakePicker implements PhotoPicker {
  int count = 2;
  final limits = <int>[];

  @override
  bool get hasCamera => false;

  @override
  Future<PickedPhoto?> takePhoto() async => null;

  @override
  Future<List<PickedPhoto>> pickFromGallery({required int limit}) async {
    limits.add(limit);
    return [
      for (var i = 0; i < count && i < limit; i++)
        PickedPhoto(name: 'foto$i.png', bytes: _png),
    ];
  }
}

Map<String, dynamic> _galleryImage(String id, int order) => {
  'id': id,
  'image': {'webpThumbnailUrl': '/images/$id.webp'},
  'sortOrder': order,
};

Map<String, dynamic> _detail({int productType = 0, bool variants = false}) => {
  'id': 'p1',
  'name': 'Arroz',
  'description': 'Grano largo',
  'category': {'id': 'c1', 'name': 'Abarrotes'},
  'productType': productType,
  'version': 3,
  'defaultTaxRate': 2,
  'defaultIepsTaxRate': 0,
  'iepsQuantityFactor': null,
  'satUnitCode': 3,
  'satProductServiceCode': '50221101',
  'brandId': 'b1',
  'brandName': 'Marca',
  'minimumStock': 5,
  'maximumStock': 50,
  'averageCost': 12.5,
  'stock': 20,
  'image': {'webpThumbnailUrl': '/images/main.webp'},
  'variants': variants
      ? [
          {'id': 'v1'},
        ]
      : <Object>[],
  'saleUnits': [
    {
      'unitOfMeasure': 1,
      'barcode': '750',
      'price': 18,
      'cost': 0,
      'isInventoryBaseUnit': true,
    },
  ],
};

class _Server {
  final requests = <RequestOptions>[];
  int saveStatus = 201;
  bool failImages = false;
  Map<String, dynamic>? detail;

  Iterable<RequestOptions> sent(String method) =>
      requests.where((request) => request.method == method);

  Future<ResponseBody> handle(RequestOptions options) async {
    requests.add(options);
    final path = options.path;

    if (options.method != 'GET') {
      final isImage = options.data is FormData;
      if (isImage && failImages) {
        return jsonResponse({'message': 'Imagen no válida.'}, 400);
      }
      if (isImage) {
        return jsonResponse({'data': _galleryImage('g9', 9)}, 200);
      }
      return jsonResponse({
        'data': {'id': 'p9'},
        if (saveStatus >= 400) 'message': 'Ese código ya existe.',
      }, saveStatus);
    }
    if (path == CategoryEndpoints.list) {
      return jsonResponse({
        'data': {
          'items': [
            {'id': 'c1', 'name': 'Abarrotes'},
            {'id': 'c2', 'name': 'Latas', 'parentCategoryName': 'Abarrotes'},
          ],
          'page': 1,
          'pageSize': 100,
          'totalCount': 2,
          'totalPages': 1,
          'hasNextPage': false,
          'hasPreviousPage': false,
        },
      }, 200);
    }
    if (path.endsWith('/gallery')) {
      return jsonResponse({
        'data': [_galleryImage('g2', 1), _galleryImage('g1', 0)],
      }, 200);
    }
    return jsonResponse({'data': detail ?? _detail()}, 200);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Server server, {
  String? productId,
  double width = 1200,
  _FakePicker? picker,
}) async {
  tester.view.physicalSize = Size(width, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(server.handle);
  final router = GoRouter(
    initialLocation: '/form',
    routes: [
      GoRoute(
        path: '/form',
        builder: (_, _) =>
            Scaffold(body: ProductFormPage(productId: productId)),
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
        photoPickerProvider.overrideWithValue(picker ?? _FakePicker()),
      ],
      child: MaterialApp.router(theme: CascaTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _input(String label) => find.descendant(
  of: find.widgetWithText(ProductField, label),
  matching: find.byType(TextField),
);

Future<void> _fill(WidgetTester tester, String label, String text) {
  return tester.enterText(_input(label), text);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _fillNewProduct(WidgetTester tester) async {
  await _fill(tester, 'Nombre', 'Arroz');
  await _fill(tester, 'Venta', '18.50');
  await _tapText(tester, 'Selecciona una categoría');
  await _tapText(tester, 'Abarrotes › Latas');
}

void main() {
  group('crear', () {
    testWidgets('exige nombre, categoría y precio', (tester) async {
      final server = _Server();
      await _pump(tester, server);

      await _tapText(tester, 'Guardar');

      expect(find.text('Ingresa el nombre'), findsOneWidget);
      expect(find.text('Selecciona una categoría'), findsNWidgets(2));
      expect(server.sent('POST'), isEmpty);
    });

    testWidgets('envía el producto y vuelve a la lista', (tester) async {
      final server = _Server();
      await _pump(tester, server);
      await _fillNewProduct(tester);
      await _fill(tester, 'Costo', '12');
      await _fill(tester, 'Stock inicial', '10');
      await _fill(tester, 'Código de barras', '750100');

      await _tapText(tester, 'Guardar');

      final post = server.sent('POST').single;
      final body = post.data as Map<String, dynamic>;
      expect(post.path, ProductEndpoints.list);
      expect(body['categoryId'], 'c2');
      expect(body['hasInitialStock'], isTrue);
      expect(body['unitCost'], 12);
      expect(body['defaultTaxRate'], 0);
      final unit = (body['saleUnits'] as List).single;
      expect(unit, containsPair('price', 18.5));
      expect(unit, containsPair('barcode', '750100'));
      expect(find.text('lista de productos'), findsOneWidget);
    });

    testWidgets('calcula la ganancia mientras se escribe', (tester) async {
      await _pump(tester, _Server());

      await _fill(tester, 'Venta', '18');
      await _fill(tester, 'Costo', '15');
      await tester.pump();

      expect(find.text(r'$3.00 (17%)'), findsOneWidget);
    });

    testWidgets('con stock inicial exige el costo', (tester) async {
      await _pump(tester, _Server());
      await _fill(tester, 'Stock inicial', '10');

      await _tapText(tester, 'Guardar');

      expect(find.text('El stock inicial necesita un costo'), findsOneWidget);
    });

    testWidgets('un servicio no muestra inventario ni código', (tester) async {
      await _pump(tester, _Server());

      await _tapText(tester, 'Servicio');

      expect(find.text('Inventario'), findsNothing);
      expect(find.text('Código de barras'), findsNothing);
    });

    testWidgets('no muestra impuestos y el guardar está en el pie', (
      tester,
    ) async {
      await _pump(tester, _Server());

      expect(find.text('Impuestos'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('product-form-footer')),
          matching: find.text('Guardar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sube las fotos después de crear el producto', (tester) async {
      final server = _Server();
      await _pump(tester, server);
      await _tapText(tester, 'Agregar foto');
      expect(find.text('Principal'), findsOneWidget);
      expect(server.sent('POST'), isEmpty);
      await _fillNewProduct(tester);

      await _tapText(tester, 'Guardar');

      expect(server.sent('POST').map((r) => r.path), [
        ProductEndpoints.list,
        ProductEndpoints.image('p9'),
        ProductEndpoints.gallery('p9'),
      ]);
      expect(find.text('lista de productos'), findsOneWidget);
    });

    testWidgets('si falla una foto reintenta sin duplicar el producto', (
      tester,
    ) async {
      final server = _Server()..failImages = true;
      await _pump(tester, server);
      await _tapText(tester, 'Agregar foto');
      await _fillNewProduct(tester);

      await _tapText(tester, 'Guardar');
      expect(
        find.text('El producto se guardó, pero algunas fotos no se subieron.'),
        findsOneWidget,
      );
      expect(find.text('Imagen no válida.'), findsOneWidget);

      server.failImages = false;
      await _tapText(tester, 'Reintentar fotos');

      final created = server
          .sent('POST')
          .where((r) => r.path == ProductEndpoints.list);
      expect(created, hasLength(1));
      expect(find.text('lista de productos'), findsOneWidget);
    });

    testWidgets('permite elegir como principal una foto secundaria', (
      tester,
    ) async {
      await _pump(tester, _Server());
      await _tapText(tester, 'Agregar foto');

      await tester.tap(find.byType(CascaActionMenu).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Hacer principal'), findsOneWidget);
    });

    testWidgets('permite cambiar una foto secundaria antes de guardar', (
      tester,
    ) async {
      final server = _Server();
      final picker = _FakePicker();
      await _pump(tester, server, picker: picker);
      await _tapText(tester, 'Agregar foto');

      await tester.tap(find.byType(CascaActionMenu).at(1));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Cambiar foto');

      expect(picker.limits.last, 1);
      expect(find.byType(CascaActionMenu), findsNWidgets(2));
      expect(server.sent('POST'), isEmpty);
    });

    testWidgets('admite una principal y seis secundarias', (tester) async {
      final picker = _FakePicker()..count = 20;
      await _pump(tester, _Server(), picker: picker);

      await _tapText(tester, 'Agregar foto');

      expect(picker.limits.single, 7);
      expect(find.byType(CascaActionMenu), findsNWidgets(7));
      expect(find.text('Agregar imagen'), findsNothing);
    });
  });

  group('editar', () {
    testWidgets('conserva marca y versión y no envía precios', (tester) async {
      final server = _Server()..saveStatus = 200;
      await _pump(tester, server, productId: 'p1');
      await _fill(tester, 'Nombre', 'Arroz integral');

      await _tapText(tester, 'Guardar');

      final put = server.sent('PUT').single;
      final body = put.data as Map<String, dynamic>;
      expect(put.path, ProductEndpoints.byId('p1'));
      expect(body['name'], 'Arroz integral');
      expect(body['version'], 3);
      expect(body['brandId'], 'b1');
      expect(body['customBrandName'], isNull);
      expect(body['satUnitCode'], 3);
      expect(body['satProductServiceCode'], isNull);
      expect(body['defaultTaxRate'], 2);
      expect(body['minimumStock'], 5);
      expect(body['maximumStock'], 50);
      expect(body.containsKey('saleUnits'), isFalse);
    });

    testWidgets('con variantes no cambia los límites de stock', (tester) async {
      final server = _Server()
        ..detail = _detail(variants: true)
        ..saveStatus = 200;
      await _pump(tester, server, productId: 'p1');

      expect(find.text('Inventario'), findsNothing);
      await _tapText(tester, 'Guardar');

      final body = server.sent('PUT').single.data as Map<String, dynamic>;
      expect(body['minimumStock'], isNull);
      expect(body['maximumStock'], isNull);
    });

    testWidgets('si guardar falla muestra el motivo', (tester) async {
      final server = _Server()..saveStatus = 409;
      await _pump(tester, server, productId: 'p1');

      await _tapText(tester, 'Guardar');

      expect(find.text('Ese código ya existe.'), findsOneWidget);
      expect(find.text('Editar producto'), findsOneWidget);
    });

    testWidgets('carga la galería y sube de inmediato una foto nueva', (
      tester,
    ) async {
      final server = _Server();
      final picker = _FakePicker()..count = 1;
      await _pump(tester, server, productId: 'p1', picker: picker);
      expect(find.byType(CascaActionMenu), findsNWidgets(3));

      await tester.tap(find.bySemanticsLabel('Agregar imagen'));
      await tester.pumpAndSettle();

      expect(server.sent('POST').single.path, ProductEndpoints.gallery('p1'));
      expect(find.byType(CascaActionMenu), findsNWidgets(4));
    });

    testWidgets('cambiar una foto secundaria conserva su lugar', (
      tester,
    ) async {
      final server = _Server();
      final picker = _FakePicker()..count = 1;
      await _pump(tester, server, productId: 'p1', picker: picker);

      await tester.tap(find.byType(CascaActionMenu).at(1));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Cambiar foto');

      expect(picker.limits.single, 1);
      final changes = server.requests.where((r) => r.method != 'GET').toList();
      expect(changes.map((r) => '${r.method} ${r.path}'), [
        'POST ${ProductEndpoints.gallery('p1')}',
        'DELETE ${ProductEndpoints.galleryImage('p1', 'g1')}',
        'PUT ${ProductEndpoints.galleryOrder('p1')}',
      ]);
      expect(changes.last.data, {
        'galleryImageIds': ['g9', 'g2'],
      });
      expect(find.byType(CascaActionMenu), findsNWidgets(3));
    });

    testWidgets('si no sube la nueva foto conserva la anterior', (
      tester,
    ) async {
      final server = _Server()..failImages = true;
      final picker = _FakePicker()..count = 1;
      await _pump(tester, server, productId: 'p1', picker: picker);

      await tester.tap(find.byType(CascaActionMenu).at(1));
      await tester.pumpAndSettle();
      await _tapText(tester, 'Cambiar foto');

      expect(server.sent('DELETE'), isEmpty);
      expect(find.byType(CascaActionMenu), findsNWidgets(3));
      expect(find.text('Imagen no válida.'), findsOneWidget);
    });

    testWidgets('eliminar una foto secundaria la borra en el servidor', (
      tester,
    ) async {
      final server = _Server();
      await _pump(tester, server, productId: 'p1');

      await tester.tap(find.byType(CascaActionMenu).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Hacer principal'), findsNothing);
      await _tapText(tester, 'Eliminar');

      expect(
        server.sent('DELETE').single.path,
        ProductEndpoints.galleryImage('p1', 'g1'),
      );
      expect(find.byType(CascaActionMenu), findsNWidgets(2));
    });
  });

  testWidgets('en teléfono usa una columna sin desbordar', (tester) async {
    await _pump(tester, _Server(), width: 360);

    expect(tester.takeException(), isNull);
    expect(find.text('Inventario'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });
}
