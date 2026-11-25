import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/stores/data/store_repository.dart';
import 'package:casca_app/features/stores/presentation/pages/store_list_page.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

const _detail = {
  'id': 's1',
  'tenantId': 't1',
  'contactInformation': {'phone': '3312345678', 'email': null},
  'businessInformation': {'name': 'Centro', 'website': 'https://casca.mx'},
  'operatingHours': {
    'openingTime': '09:00:00',
    'closingTime': '18:00:00',
    'is24Hours': false,
  },
  'operationalStatus': {
    'isOpen': true,
    'isUnderMaintenance': false,
    'isActive': true,
  },
  'address': {
    'street': 'Juárez',
    'city': 'Guadalajara',
    'state': 'Jalisco',
    'country': 'México',
    'postalCode': '44100',
    'municipality': 'Guadalajara',
    'interiorNumber': null,
    'exteriorNumber': '10',
  },
  'socialMediaLinks': [
    {'platform': 'web', 'url': 'https://casca.mx'},
  ],
  'settings': {
    'taxesEnabled': true,
    'defaultTaxRate': 2,
    'pricesIncludeTax': false,
  },
};

Future<List<RequestOptions>> _pump(
  WidgetTester tester, {
  double width = 1000,
  List<String> permissions = const [
    'store.view',
    'store.create',
    'store.update',
  ],
}) async {
  tester.view.physicalSize = Size(width, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter((options) async {
      requests.add(options);
      if (options.method != 'GET') return jsonResponse({'data': null}, 200);
      if (options.path != StoreEndpoints.list) {
        return jsonResponse({'data': _detail}, 200);
      }
      return jsonResponse({
        'data': {
          'items': [
            {
              'id': 's1',
              'name': 'Centro',
              'phone': '3312345678',
              'email': '',
              'isActive': true,
            },
          ],
          'page': 1,
          'pageSize': 10,
          'totalCount': 1,
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
        home: const Scaffold(body: StoreListPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

Finder _input(String hint) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.hintText == hint,
);

void main() {
  testWidgets('lista las sucursales ordenadas por nombre', (tester) async {
    final requests = await _pump(tester);

    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
    expect(requests.single.queryParameters, {
      'sortColumn': 'name',
      'sortOrder': 'asc',
      'page': 1,
      'pageSize': 10,
    });
  });

  testWidgets('editar conserva lo que el formulario no cambia', (tester) async {
    final requests = await _pump(tester);

    await tester.tap(find.byType(CascaActionMenu).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(_input('Ej. Sucursal Centro'), 'Matriz');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final put = requests.singleWhere((r) => r.method == 'PUT');
    final body = put.data as Map<String, dynamic>;
    expect(put.path, StoreEndpoints.byId('s1'));
    expect(body['businessInformation'], {
      'name': 'Matriz',
      'website': 'https://casca.mx',
    });
    expect(body['operatingHours'], _detail['operatingHours']);
    expect(body['socialMediaLinks'], _detail['socialMediaLinks']);
    expect(body['defaultTaxRate'], 2);
    expect(body['pricesIncludeTax'], isFalse);
    expect((body['contactInformation'] as Map)['email'], isNull);
  });

  testWidgets('agregar valida y envía el negocio de la sesión', (tester) async {
    final requests = await _pump(tester);

    await tester.tap(find.text('Agregar sucursal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa el nombre'), findsOneWidget);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);

    for (final (hint, value) in [
      ('Ej. Sucursal Centro', 'Norte'),
      ('Ej. Av. Juárez', 'Hidalgo'),
      ('Ej. Jalisco', 'Jalisco'),
      ('Ej. 44100', '44200'),
    ]) {
      await tester.enterText(_input(hint), value);
    }
    await tester.enterText(_input('Ej. Guadalajara').at(0), 'Zapopan');
    await tester.enterText(_input('Ej. Guadalajara').at(1), 'Zapopan');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final post = requests.singleWhere((r) => r.method == 'POST');
    final body = post.data as Map<String, dynamic>;
    expect(body['tenantId'], 't1');
    expect(body['isDefault'], isFalse);
    expect((body['address'] as Map)['country'], 'México');
  });

  testWidgets('en teléfono oculta el contacto y el formulario no desborda', (
    tester,
  ) async {
    await _pump(tester, width: 360);

    expect(find.text('Teléfono'), findsNothing);
    await tester.tap(find.text('Agregar sucursal'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('sin permisos no ofrece agregar ni editar', (tester) async {
    await _pump(tester, permissions: const ['store.view']);

    expect(find.text('Agregar sucursal'), findsNothing);
    expect(find.byType(CascaActionMenu), findsNothing);
  });
}
