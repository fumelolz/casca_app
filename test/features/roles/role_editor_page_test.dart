import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/roles/data/models/role_models.dart';
import 'package:casca_app/features/roles/domain/permission_rules.dart';
import 'package:casca_app/features/roles/presentation/pages/role_editor_page.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

const _group = PermissionGroupModel(
  key: 'sale',
  label: 'Ventas',
  permissions: [
    PermissionModel(key: 'sale.view', description: 'Ver', grantable: true),
    PermissionModel(key: 'sale.create', description: 'Crear', grantable: true),
    PermissionModel(key: 'sale.refund', description: 'Devo', grantable: false),
  ],
);

final _session = SessionState.fromJson({
  'account': {'id': 'a1', 'email': 'x@y.com', 'name': 'X'},
  'roles': <Object>[],
  'permissions': ['role.view', 'role.update'],
  'store': {
    'id': 's1',
    'name': 'Centro',
    'taxesEnabled': false,
    'isDefault': true,
    'tenantId': 't1',
    'tenantName': 'Casca Demo',
    'businessType': null,
  },
});

void main() {
  test('marcar un grupo no toca lo que no se puede asignar', () {
    expect(groupValue(_group, {'sale.view'}), isNull);
    expect(groupValue(_group, {'sale.view', 'sale.create'}), isTrue);
    expect(setGroup(_group, {'sale.refund'}, checked: true), {
      'sale.view',
      'sale.create',
      'sale.refund',
    });
    expect(setGroup(_group, {'sale.view', 'sale.refund'}, checked: false), {
      'sale.refund',
    });
  });

  testWidgets('edita los permisos de un rol y los guarda', (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeHttpAdapter((options) async {
        requests.add(options);
        if (options.path.endsWith('/permissions')) {
          return jsonResponse({
            'data': [
              {
                'key': 'sale',
                'label': 'Ventas',
                'permissions': [
                  {
                    'key': 'sale.view',
                    'description': 'Ver ventas',
                    'grantable': true,
                  },
                  {
                    'key': 'sale.create',
                    'description': 'Registrar ventas',
                    'grantable': true,
                  },
                ],
              },
            ],
          }, 200);
        }
        return jsonResponse({
          'data': {
            'id': 'r1',
            'name': 'Cajero',
            'description': null,
            'isSystem': false,
            'permissionKeys': ['sale.view'],
            'employeeCount': 2,
          },
        }, 200);
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
    final router = GoRouter(
      initialLocation: '/roles/r1',
      routes: [
        GoRoute(
          path: '/roles/r1',
          builder: (context, state) =>
              const Scaffold(body: RoleEditorPage(roleId: 'r1')),
        ),
        GoRoute(
          path: '/roles',
          builder: (context, state) => const Scaffold(body: Text('lista')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: CascaTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    CascaButton save() => tester.widget<CascaButton>(
      find.widgetWithText(CascaButton, 'Guardar cambios'),
    );
    expect(save().onPressed, isNull);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is CascaCheckbox &&
            widget.semanticLabel == 'Registrar ventas',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CascaButton, 'Guardar cambios'));
    await tester.pumpAndSettle();

    final saved = requests.singleWhere((request) => request.method == 'PUT');
    expect(saved.data, {
      'name': 'Cajero',
      'description': null,
      'permissionKeys': ['sale.create', 'sale.view'],
    });
    expect(find.text('lista'), findsOneWidget);
  });
}
