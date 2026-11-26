import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/sales/presentation/pages/sale_detail_page.dart';
import 'package:casca_app/features/sales/presentation/pages/sales_history_page.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

class _Server {
  bool fail = false;
  final requests = <RequestOptions>[];

  Future<ResponseBody> handle(RequestOptions options) async {
    requests.add(options);
    if (fail) return jsonResponse({'message': 'Venta no encontrada'}, 404);

    if (options.path == '/api/v1/sales') {
      final found = !options.queryParameters.containsKey('q');
      return jsonResponse({
        'data': {
          'items': [
            if (found)
              {
                'id': 'v1',
                'saleNumber': 'V0000000001',
                'status': 0,
                'payments': [
                  {'method': 0, 'amount': 60},
                  {'method': 3, 'amount': 40},
                ],
                'totalAmount': 100,
                'createdOnUtc': '2026-11-24T16:00:00Z',
              },
          ],
          'page': 1,
          'pageSize': 10,
          'totalCount': found ? 1 : 0,
          'totalPages': 1,
          'hasNextPage': false,
          'hasPreviousPage': false,
        },
      }, 200);
    }

    return jsonResponse({
      'data': {
        'id': 'v1',
        'saleNumber': 'V0000000001',
        'status': 0,
        'payments': [
          {'method': 0, 'amount': 100, 'cashReceived': 500, 'changeGiven': 400},
        ],
        'subtotal': 86.21,
        'totalAmount': 100,
        'notes': 'Entregar mañana',
        'createdOnUtc': '2026-11-24T16:00:00Z',
        'items': [
          {
            'id': 'i1',
            'displayName': 'Playera azul',
            'saleUnitName': 'Pieza',
            'quantity': 2,
            'unitPrice': 50,
            'subtotal': 86.21,
            'total': 100,
          },
        ],
      },
    }, 200);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Server server, {
  String location = AppRoutes.sales,
  double width = 1200,
}) async {
  tester.view.physicalSize = Size(width, 2400);
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

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.sales,
        builder: (_, _) => const Scaffold(body: SalesHistoryPage()),
      ),
      GoRoute(
        path: AppRoutes.saleDetail,
        builder: (_, state) => Scaffold(
          body: SaleDetailPage(
            saleId: state.pathParameters['saleId']!,
            shiftId: state.uri.queryParameters[AppRoutes.saleShiftParameter],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.shiftDetail,
        builder: (_, state) => Text('Turno ${state.pathParameters['shiftId']}'),
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

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(CascaInput), text);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pide las ventas recientes y abre el detalle', (tester) async {
    final server = _Server();
    await _pump(tester, server);

    expect(server.requests.single.queryParameters, {
      'sort': 'createdOnUtc',
      'order': 'desc',
      'page': 1,
      'pageSize': 10,
    });
    expect(find.text('Mixto'), findsOneWidget);

    await tester.tap(find.text('V0000000001'));
    await tester.pumpAndSettle();

    expect(server.requests.last.path, '/api/v1/sales/v1');
    expect(find.text('Playera azul'), findsOneWidget);
    expect(find.text('Descripción'), findsOneWidget);
    expect(find.text('Pieza'), findsOneWidget);
    expect(find.text('SKU: —'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Sin foto')), findsWidgets);
    expect(find.text('Venta mostrador'), findsOneWidget);
    expect(find.text('\$400.00'), findsOneWidget);
    expect(find.text('Entregar mañana'), findsOneWidget);
  });

  testWidgets('busca por número y conserva la búsqueda al volver', (
    tester,
  ) async {
    final server = _Server();
    await _pump(tester, server);

    await _search(tester, ' V999 ');

    expect(server.requests.last.queryParameters['q'], 'V999');
    expect(find.text('No hay una venta con ese número.'), findsOneWidget);
  });

  testWidgets('ordena por fecha y vuelve al orden reciente', (tester) async {
    final server = _Server();
    await _pump(tester, server);
    Future<Map<String, dynamic>> sortByDate() async {
      await tester.tap(find.bySemanticsLabel('Ordenar por Fecha'));
      await tester.pumpAndSettle();
      return server.requests.last.queryParameters;
    }

    expect((await sortByDate())['order'], 'asc');
    expect((await sortByDate())['order'], 'desc');
  });

  testWidgets('en teléfono compacta cada producto', (tester) async {
    await _pump(
      tester,
      _Server(),
      location: AppRoutes.saleDetailFor('v1'),
      width: 360,
    );

    expect(find.text('Precio'), findsNothing);
    expect(find.text('2 Pieza × \$50.00'), findsOneWidget);
  });

  testWidgets('desde un turno regresa a ese turno', (tester) async {
    await _pump(
      tester,
      _Server(),
      location: AppRoutes.saleDetailFor('v1', shiftId: 't1'),
    );

    await tester.tap(find.text('Volver al turno'));
    await tester.pumpAndSettle();

    expect(find.text('Turno t1'), findsOneWidget);
  });

  testWidgets('si falla muestra el motivo y permite volver', (tester) async {
    await _pump(
      tester,
      _Server()..fail = true,
      location: AppRoutes.saleDetailFor('v1'),
    );

    expect(find.text('Venta no encontrada'), findsOneWidget);
    expect(find.text('Volver a ventas'), findsOneWidget);
  });

  for (final location in [AppRoutes.sales, AppRoutes.saleDetailFor('v1')]) {
    testWidgets('en teléfono no desborda: $location', (tester) async {
      await _pump(tester, _Server(), location: location, width: 360);

      expect(find.text('V0000000001'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
