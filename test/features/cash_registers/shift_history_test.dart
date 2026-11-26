import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/shift_detail_page.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/shift_history_page.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

Map<String, dynamic> _paged(List<Object?> items, {int total = 1}) => {
  'items': items,
  'page': 1,
  'pageSize': 20,
  'totalCount': total,
  'totalPages': 1,
  'hasNextPage': false,
  'hasPreviousPage': false,
};

class _Server {
  _Server({this.closed = true});

  final bool closed;
  bool fail = false;
  final requests = <RequestOptions>[];

  Future<ResponseBody> handle(RequestOptions options) async {
    requests.add(options);
    if (fail) return jsonResponse({'message': 'Turno no encontrado'}, 404);

    if (options.path.endsWith('/shifts')) {
      return jsonResponse({
        'data': _paged([
          {
            'cashRegisterShiftId': 't1',
            'cashRegisterName': 'Caja principal',
            'userName': 'Daniel',
            'isClosed': closed,
            'initialAmount': 500,
            'openedAt': '2026-11-24T15:00:00Z',
            'closedAt': closed ? '2026-11-24T23:00:00Z' : null,
            'totalSales': 1250,
            'difference': closed ? -20 : null,
          },
        ]),
      }, 200);
    }
    return jsonResponse({
      'data': {
        'shift': {
          'cashRegisterName': 'Caja principal',
          'userName': 'Daniel',
          'openedAt': '2026-11-24T15:00:00Z',
          'closedAt': closed ? '2026-11-24T23:00:00Z' : null,
          'initialAmount': 500,
          'expectedCash': closed ? 1400 : null,
          'countedCash': closed ? 1380 : null,
          'difference': closed ? -20 : null,
          'closingNotes': closed ? 'Faltó cambio' : null,
          'closedByUserName': closed ? 'Ana' : null,
          'withdrawnAtClose': closed ? 880 : null,
          'leftInCash': closed ? 500 : null,
        },
        'summary': {
          'cashSales': 900,
          'nonCashSales': 350,
          'cashIn': 100,
          'cashOut': 100,
          'totalSales': 1250,
        },
        'movements': _paged([
          {
            'type': 'Withdrawal',
            'amount': 100,
            'notes': 'Pago a proveedor',
            'createdAt': '2026-11-24T18:00:00Z',
            'userName': 'Daniel',
          },
        ]),
        'sales': _paged([
          {
            'saleId': 'v1',
            'saleNumber': 'V-0001',
            'total': 350,
            'createdAt': '2026-11-24T16:00:00Z',
            'paymentBreakdown': [
              {'method': 'DebitCard', 'amount': 350},
            ],
          },
        ], total: 45),
        'paymentCounts': closed
            ? [
                {
                  'method': 3,
                  'expectedAmount': 350,
                  'countedAmount': 350,
                  'difference': 0,
                },
              ]
            : [],
      },
    }, 200);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Server server, {
  String location = '/cash-register/shift-history/t1',
  double width = 1200,
}) async {
  tester.view.physicalSize = Size(width, 3200);
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
        path: AppRoutes.shiftHistory,
        builder: (_, _) => const Scaffold(body: ShiftHistoryPage()),
      ),
      GoRoute(
        path: AppRoutes.shiftDetail,
        builder: (_, state) => Scaffold(
          body: ShiftDetailPage(shiftId: state.pathParameters['shiftId']!),
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

void main() {
  testWidgets('el historial pide los turnos recientes y abre el detalle', (
    tester,
  ) async {
    final server = _Server();
    await _pump(tester, server, location: AppRoutes.shiftHistory);

    expect(server.requests.single.queryParameters, {
      'sort': 'openedAt',
      'order': 'desc',
      'page': 1,
      'pageSize': 10,
    });
    expect(find.text('Faltan \$20.00'), findsOneWidget);
    await tester.tap(find.text('Caja principal'));
    await tester.pumpAndSettle();

    expect(find.byType(ShiftDetailPage), findsOneWidget);
  });

  testWidgets('un turno cerrado muestra el corte y los movimientos', (
    tester,
  ) async {
    await _pump(tester, _Server());

    expect(find.text('Turno cerrado'), findsOneWidget);
    expect(find.text('Cerrado por: Ana'), findsOneWidget);
    expect(find.text('Corte por método de pago'), findsOneWidget);
    expect(
      find.text('Esperado \$1,750.00 · Contado \$1,730.00'),
      findsOneWidget,
    );
    expect(find.text('Retiro'), findsOneWidget);
    expect(find.text('Tarjeta de Débito: \$350.00'), findsOneWidget);
    expect(find.text('Nota de cierre: Faltó cambio'), findsOneWidget);
  });

  testWidgets('un turno abierto calcula el efectivo esperado sin corte', (
    tester,
  ) async {
    await _pump(tester, _Server(closed: false));

    expect(find.text('Turno abierto'), findsOneWidget);
    expect(find.text('\$1,400.00'), findsOneWidget);
    expect(find.text('Corte por método de pago'), findsNothing);
  });

  testWidgets('cambiar de página en ventas conserva el detalle', (
    tester,
  ) async {
    final server = _Server();
    await _pump(tester, server);

    await tester.tap(find.bySemanticsLabel('Página siguiente').last);
    await tester.pumpAndSettle();

    expect(server.requests.last.queryParameters['salesPage'], 2);
    expect(server.requests.last.queryParameters['movementsPage'], 1);
    expect(find.text('Turno cerrado'), findsOneWidget);
  });

  testWidgets('si falla muestra el motivo y permite volver', (tester) async {
    await _pump(tester, _Server()..fail = true);

    expect(find.text('Turno no encontrado'), findsOneWidget);
    await tester.tap(find.text('Volver al historial'));
    await tester.pumpAndSettle();

    expect(find.byType(ShiftHistoryPage), findsOneWidget);
  });

  for (final location in [
    AppRoutes.shiftHistory,
    '/cash-register/shift-history/t1',
  ]) {
    testWidgets('en teléfono no desborda: $location', (tester) async {
      await _pump(tester, _Server(), location: location, width: 360);

      expect(find.text('Caja principal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
