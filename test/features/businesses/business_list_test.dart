import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/businesses/domain/business_rules.dart';
import 'package:casca_app/features/businesses/presentation/pages/business_list_page.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

Map<String, dynamic> _store(String id, String name, String tenant) => {
  'id': id,
  'name': name,
  'taxesEnabled': false,
  'isDefault': id == 's1',
  'tenantId': tenant,
  'tenantName': tenant == 't1' ? 'Abarrotes Lupita' : 'Plasticos Lupita',
  'businessType': tenant == 't1' ? 'abarrotes' : null,
};

final _stores = [
  _store('s1', 'Centro', 't1'),
  _store('s2', 'Norte', 't1'),
  _store('s3', 'Taxco', 't2'),
];

Map<String, dynamic> _sessionJson(
  Map<String, dynamic> active, {
  String role = 'Administrador',
}) => {
  'account': {'id': 'a1', 'email': 'x@y.com', 'name': 'Ana'},
  'roles': [
    {'id': 'r1', 'name': role},
  ],
  'permissions': <String>[],
  'store': active,
  'stores': _stores,
};

class _Server {
  String? failure;
  bool invited = true;
  final requests = <RequestOptions>[];

  List<RequestOptions> get posts =>
      requests.where((request) => request.method == 'POST').toList();

  Future<ResponseBody> handle(RequestOptions options) async {
    requests.add(options);
    if (options.method == 'GET') {
      return jsonResponse({
        'data': [
          if (invited)
            {
              'invitationId': 'i1',
              'storeName': 'Sur',
              'tenantName': 'Joyas Ana',
              'businessType': 'joyeria',
              'roleName': 'Cajero',
            },
        ],
      }, 200);
    }

    final failure = this.failure;
    if (failure != null) return jsonResponse({'message': failure}, 400);
    if (options.path.contains('/invitations/')) {
      invited = false;
      return jsonResponse({'data': null}, 200);
    }
    return jsonResponse({'data': _sessionJson(_stores.last)}, 200);
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _Server server, {
  String role = 'Administrador',
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
        FakeAuthRepository(
          hasSession: true,
          session: SessionState.fromJson(
            _sessionJson(_stores.first, role: role),
          ),
        ),
      ),
      apiClientProvider.overrideWithValue(ApiClient(dio, DefaultCookieJar())),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.notifier).restoreSession();

  final router = GoRouter(
    initialLocation: AppRoutes.businesses,
    routes: [
      GoRoute(
        path: AppRoutes.businesses,
        builder: (_, _) => const Scaffold(body: BusinessListPage()),
      ),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('Inicio')),
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
  return container;
}

Finder _button(String label) => find.widgetWithText(CascaButton, label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _activeStore(ProviderContainer container) {
  return container.read(authControllerProvider).session!.activeStore.id;
}

void main() {
  test('las iniciales usan dos palabras o dos letras', () {
    expect(businessInitials('Plasticos lupita'), 'PL');
    expect(businessInitials('abarrotes'), 'AB');
    expect(businessInitials('   '), '?');
  });

  testWidgets('agrupa las sucursales por negocio y despliega el activo', (
    tester,
  ) async {
    await _pump(tester, _Server());

    expect(find.text('2 sucursales vinculadas'), findsOneWidget);
    expect(find.text('1 sucursal vinculada'), findsOneWidget);
    expect(find.text('Negocio activo'), findsOneWidget);
    expect(find.text('Sucursal en uso'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Norte'), findsOneWidget);
    expect(find.text('Taxco'), findsNothing);
  });

  testWidgets('cambia de sucursal y vuelve al inicio', (tester) async {
    final server = _Server();
    final container = await _pump(tester, server);

    await _tap(tester, find.text('Plasticos Lupita'));
    await _tap(tester, _button('Usar esta sucursal').last);

    expect(server.posts.single.path, '/api/v1/auth/switch-store');
    expect(server.posts.single.data, {'storeId': 's3'});
    expect(_activeStore(container), 's3');
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('si no puede cambiar conserva la sucursal', (tester) async {
    final server = _Server()..failure = 'Sin acceso a la sucursal';
    final container = await _pump(tester, server);

    await _tap(tester, _button('Usar esta sucursal'));

    expect(find.text('Sin acceso a la sucursal'), findsOneWidget);
    expect(_activeStore(container), 's1');
  });

  testWidgets('aceptar una invitación la quita de la lista', (tester) async {
    final server = _Server();
    await _pump(tester, server);

    await _tap(tester, _button('Aceptar invitación'));

    expect(server.posts.single.path, '/api/v1/invitations/i1/accept');
    expect(find.text('Invitaciones pendientes'), findsNothing);
  });

  testWidgets('rechazar usa su propia ruta', (tester) async {
    final server = _Server();
    await _pump(tester, server);

    await _tap(tester, _button('Rechazar'));

    expect(server.posts.single.path, '/api/v1/invitations/i1/decline');
  });

  testWidgets('crea un negocio y cambia a él', (tester) async {
    final server = _Server();
    final container = await _pump(tester, server);
    await _tap(tester, _button('Agregar negocio'));

    await _tap(tester, _button('Crear negocio'));
    expect(find.text('Ingresa el nombre'), findsOneWidget);
    expect(server.posts, isEmpty);

    await tester.enterText(find.byType(CascaInput), ' Plasticos Lupita ');
    await _tap(tester, find.text('Selecciona un giro').first);
    await _tap(tester, find.text('Otro').last);
    await _tap(tester, _button('Crear negocio'));

    expect(server.posts.single.data, {
      'name': 'Plasticos Lupita',
      'businessType': 'otro',
    });
    expect(_activeStore(container), 's3');
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.byType(CascaSelect<Object>), findsNothing);
  });

  testWidgets('solo un administrador puede agregar negocios', (tester) async {
    await _pump(tester, _Server(), role: 'Cajero');

    expect(_button('Agregar negocio'), findsNothing);
  });

  testWidgets('en teléfono no desborda', (tester) async {
    await _pump(tester, _Server(), width: 360);

    expect(find.text('Centro'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
