import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/price_lists/domain/price_list_rules.dart';
import 'package:casca_app/features/price_lists/presentation/pages/price_list_detail_page.dart';
import 'package:casca_app/features/price_lists/presentation/pages/price_list_page.dart';
import 'package:casca_app/features/price_lists/presentation/widgets/price_list_detail_skeleton.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

const _list = {'id': 'l1', 'name': 'Mayorista', 'priceCount': 1};

Map<String, dynamic> _item(String id, String name) => {
  'sellableItemId': id,
  'displayName': name,
  'sku': id,
  'price': 100,
};

class _Server {
  bool failSave = false;
  final requests = <RequestOptions>[];

  List<RequestOptions> sent(String method) =>
      requests.where((r) => r.method == method).toList();

  Future<ResponseBody> handle(RequestOptions options) async {
    requests.add(options);
    final path = options.path;

    if (path.endsWith('/pos/catalog')) {
      return jsonResponse({
        'data': {
          'items': [_item('a', 'Playera'), _item('b', 'Gorra')],
          'page': 1,
          'pageSize': 25,
          'totalCount': 2,
          'totalPages': 1,
          'hasNextPage': false,
          'hasPreviousPage': false,
        },
      }, 200);
    }
    if (path.endsWith('/prices')) {
      if (options.method == 'GET') {
        return jsonResponse({
          'data': [
            {'sellableItemId': 'a', 'price': 80},
          ],
        }, 200);
      }
      return failSave
          ? jsonResponse({'message': 'Precio rechazado'}, 400)
          : jsonResponse({'data': null}, 200);
    }
    if (path.endsWith('/price-lists') && options.method == 'GET') {
      return jsonResponse({
        'data': [_list],
      }, 200);
    }
    return jsonResponse({'data': _list}, 200);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Server server, {
  String location = '/price-lists/l1',
  double width = 1200,
}) async {
  tester.view.physicalSize = Size(width, 1800);
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
            permissions: [
              'pricelist.view',
              'pricelist.create',
              'pricelist.update',
              'pricelist.delete',
            ],
          ),
        ),
      ),
      apiClientProvider.overrideWithValue(ApiClient(dio, DefaultCookieJar())),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.notifier).restoreSession();

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.priceLists,
        builder: (_, _) => const Scaffold(body: PriceListPage()),
      ),
      GoRoute(
        path: AppRoutes.priceListDetail,
        builder: (_, state) => Scaffold(
          body: PriceListDetailPage(
            priceListId: state.pathParameters['priceListId']!,
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: CascaTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _price(String id) => find.descendant(
  of: find.byKey(ValueKey('list-price-$id')),
  matching: find.byType(TextField),
);

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  test('volver al precio guardado quita el cambio pendiente', () {
    final changed = withPendingChange({}, {'a': 80}, 'a', 90);

    expect(changed, {'a': 90});
    expect(withPendingChange(changed, {'a': 80}, 'a', 80), isEmpty);
    expect(withPendingChange({}, {'a': 80}, 'a', null), {'a': null});
  });

  test('envía los precios en grupos de 500', () {
    final pending = {for (var i = 0; i < 501; i++) '$i': 1.0};

    expect(priceBatches(pending).map((batch) => batch.length), [500, 1]);
  });

  testWidgets('la lista incluye Público y abre el detalle', (tester) async {
    await _pump(tester, _Server(), location: AppRoutes.priceLists);

    expect(find.text('Público (Por defecto)'), findsOneWidget);
    expect(find.text('1 precio'), findsOneWidget);
    await _tap(tester, 'Mayorista');

    expect(find.byType(PriceListDetailPage), findsOneWidget);
  });

  testWidgets('crea una lista y entra a capturar sus precios', (tester) async {
    final server = _Server();
    await _pump(tester, server, location: AppRoutes.priceLists);

    await _tap(tester, 'Agregar lista');
    await tester.enterText(find.byType(TextField), 'Mayorista');
    await _tap(tester, 'Crear lista');

    expect(server.sent('POST').single.data, {'name': 'Mayorista'});
    expect(find.byType(PriceListDetailPage), findsOneWidget);
  });

  testWidgets('guarda solo los precios que cambiaron', (tester) async {
    final server = _Server();
    await _pump(tester, server);
    expect(tester.widget<TextField>(_price('a')).controller!.text, '80');

    await tester.enterText(_price('a'), '');
    await tester.enterText(_price('b'), '55.5');
    await tester.pumpAndSettle();
    await _tap(tester, 'Guardar cambios (2)');

    expect(server.sent('PUT').single.data, {
      'prices': [
        {'sellableItemId': 'a', 'price': null},
        {'sellableItemId': 'b', 'price': 55.5},
      ],
    });
    expect(find.text('Guardar cambios'), findsOneWidget);
  });

  testWidgets('descartar recupera el precio guardado', (tester) async {
    await _pump(tester, _Server());

    await tester.enterText(_price('a'), '10');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await _tap(tester, 'Descartar');

    expect(tester.widget<TextField>(_price('a')).controller!.text, '80');
  });

  testWidgets('si falla al guardar conserva los cambios', (tester) async {
    await _pump(tester, _Server()..failSave = true);

    await tester.enterText(_price('b'), '55');
    await tester.pumpAndSettle();
    await _tap(tester, 'Guardar cambios (1)');

    expect(find.text('Precio rechazado'), findsOneWidget);
    expect(find.text('Guardar cambios (1)'), findsOneWidget);
  });

  testWidgets('el esqueleto de carga cabe en teléfono', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: CascaTheme.light,
        home: const Scaffold(body: PriceListDetailSkeleton()),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('en teléfono captura precios sin desbordar', (tester) async {
    await _pump(tester, _Server(), width: 360);

    expect(_price('a'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
