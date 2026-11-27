import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/home/data/dashboard_repository.dart';
import 'package:casca_app/features/home/domain/dashboard_rules.dart';
import 'package:casca_app/features/home/presentation/pages/home_page.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

const _summary = <String, dynamic>{
  'sales': {
    'todayTotal': 4580.5,
    'todayOrders': 23,
    'avgTicket': 199.15,
    'yesterdayTotal': 3900,
    'difference': 680.5,
    'percentageChange': 17.45,
  },
  'topProducts': [
    {'productId': 'p1', 'name': 'Arroz', 'quantity': 14, 'revenue': 350},
  ],
  'lowStock': [
    {'productId': 'p2', 'name': 'Frijol', 'stock': 0, 'minimumStock': 10},
  ],
  'paymentMethods': [
    {'method': 'Efectivo', 'total': 3000},
    {'method': 'Tarjeta de débito', 'total': 1580.5},
  ],
  'profit': {'todayProfit': 910},
  'generatedAt': '2026-11-26T18:00:00Z',
};

final _session = SessionState.fromJson({
  'account': {'id': 'a1', 'email': 'x@y.com', 'name': 'Daniel Prueba'},
  'roles': <Object>[],
  'permissions': ['dashboard.view'],
  'store': {
    'id': 's1',
    'name': 'Sucursal Centro',
    'taxesEnabled': false,
    'isDefault': true,
    'tenantId': 't1',
    'tenantName': 'Casca Demo',
    'businessType': null,
  },
});

void main() {
  test('respeta lo oculto y el orden guardado en la web', () {
    final blocks = visibleBlocks([
      (key: 'low-stock', enabled: true, order: 0),
      (key: 'profit-today', enabled: false, order: 1),
      (key: 'metal-gold', enabled: true, order: 2),
      (key: 'sales-today', enabled: true, order: 3),
    ]);

    expect(blocks.take(2), [
      DashboardBlock.lowStock,
      DashboardBlock.salesToday,
    ]);
    expect(blocks, isNot(contains(DashboardBlock.profitToday)));
    expect(visibleBlocks(const []), DashboardBlock.values);
  });

  test('en pantallas anchas junta cada pareja en una fila', () {
    final rows = mergeMetrics(columnRows(DashboardBlock.values));

    expect(rows, [
      [DashboardBlock.salesToday, DashboardBlock.paymentMethods],
      [
        DashboardBlock.ordersToday,
        DashboardBlock.averageTicket,
        DashboardBlock.profitToday,
      ],
      [DashboardBlock.topProducts, DashboardBlock.lowStock],
    ]);
    expect(columnRows([DashboardBlock.lowStock]), [
      [DashboardBlock.lowStock],
    ]);
  });

  testWidgets('muestra el resumen en teléfono sin desbordar', (tester) async {
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeHttpAdapter((options) async {
        if (options.path == DashboardEndpoints.layout) {
          return jsonResponse({
            'data': {'widgets': <Object>[]},
          }, 200);
        }
        return jsonResponse({'data': _summary}, 200);
      });
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(hasSession: true, session: _session),
        ),
        apiClientProvider.overrideWithValue(ApiClient(dio, DefaultCookieJar())),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: CascaTheme.light,
          home: const Scaffold(body: HomePage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hola, Daniel'), findsOneWidget);
    expect(find.text('+17.5 % vs. ayer'), findsOneWidget);
    expect(find.text('Efectivo · 65 %'), findsOneWidget);
    expect(find.text('Agotado'), findsOneWidget);
  });
}
