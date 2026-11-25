import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/cash_registers/data/cash_register_repository.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/cash_register_list_page.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

const _all = [
  'cashregister.view',
  'cashregister.create',
  'cashregister.update',
  'cashregister.delete',
];

Future<List<RequestOptions>> _pump(
  WidgetTester tester, {
  double width = 1000,
  List<String> permissions = _all,
  int deleteStatus = 204,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter((options) async {
      requests.add(options);
      if (options.method == 'DELETE') {
        return jsonResponse({
          'message': 'No puedes eliminar una caja abierta.',
        }, deleteStatus);
      }
      if (options.method != 'GET') return jsonResponse({'data': null}, 200);
      return jsonResponse({
        'data': {
          'items': [
            {
              'id': 'r1',
              'name': 'Caja principal',
              'description': 'Mostrador',
              'isOpen': true,
            },
            {
              'id': 'r2',
              'name': 'Caja dos',
              'description': null,
              'isOpen': false,
            },
          ],
          'page': 1,
          'pageSize': 10,
          'totalCount': 2,
          'totalPages': 1,
          'hasNextPage': false,
          'hasPreviousPage': false,
        },
      }, 200);
    });

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
      child: MaterialApp(
        theme: CascaTheme.light,
        home: const Scaffold(body: CashRegisterListPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

Future<void> _chooseRowAction(WidgetTester tester, String label) async {
  await tester.tap(find.byType(CascaActionMenu).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra las cajas con su estado y pide orden por nombre', (
    tester,
  ) async {
    final requests = await _pump(tester);

    expect(find.text('Caja principal'), findsOneWidget);
    expect(find.text('Abierta'), findsOneWidget);
    expect(find.text('Cerrada'), findsOneWidget);
    expect(requests.single.queryParameters, {
      'sort': 'name',
      'order': 'asc',
      'page': 1,
      'pageSize': 10,
    });
  });

  testWidgets('filtrar por estado envía isOpen', (tester) async {
    final requests = await _pump(tester);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerradas'));
    await tester.pumpAndSettle();

    expect(requests.last.queryParameters['isOpen'], isFalse);
  });

  testWidgets('en teléfono oculta la descripción sin desbordar', (
    tester,
  ) async {
    await _pump(tester, width: 360);

    expect(find.text('Mostrador'), findsNothing);
    expect(find.text('Abierta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editar guarda con PUT', (tester) async {
    final requests = await _pump(tester);

    await _chooseRowAction(tester, 'Editar');
    await tester.enterText(
      find.widgetWithText(TextField, 'Caja principal'),
      'Caja uno',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final put = requests.singleWhere((r) => r.method == 'PUT');
    expect(put.path, CashRegisterEndpoints.byId('r1'));
    expect(put.data, {'name': 'Caja uno', 'description': 'Mostrador'});
    expect(find.text('Guardar'), findsNothing);
  });

  testWidgets('agregar exige nombre y guarda con POST', (tester) async {
    final requests = await _pump(tester);

    await tester.tap(find.text('Agregar caja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa el nombre'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), 'Caja tres');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final post = requests.singleWhere((r) => r.method == 'POST');
    expect(post.data, {'name': 'Caja tres', 'description': null});
  });

  testWidgets('si el backend rechaza eliminar muestra el motivo', (
    tester,
  ) async {
    await _pump(tester, deleteStatus: 409);

    await _chooseRowAction(tester, 'Eliminar');
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('No puedes eliminar una caja abierta.'), findsOneWidget);
  });

  testWidgets('sin permisos no ofrece agregar ni acciones', (tester) async {
    await _pump(tester, permissions: const ['cashregister.view']);

    expect(find.text('Agregar caja'), findsNothing);
    expect(find.byType(CascaActionMenu), findsNothing);
  });
}
