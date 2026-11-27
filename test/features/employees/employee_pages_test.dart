import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/employees/data/employee_repository.dart';
import 'package:casca_app/features/employees/presentation/pages/employee_detail_page.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

final _session = SessionState.fromJson({
  'account': {'id': 'a1', 'email': 'x@y.com', 'name': 'X'},
  'roles': <Object>[],
  'permissions': [
    'storeuser.view',
    'storeuser.update',
    'cashregister.access.manage',
  ],
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('desactiva al empleado y guarda sus cajas', (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeHttpAdapter((options) async {
        requests.add(options);
        if (options.method != 'GET') return jsonResponse({'data': null}, 200);
        if (options.path.endsWith('/cash-registers')) {
          return jsonResponse({
            'data': [
              {'cashRegisterId': 'c1', 'name': 'Caja 1', 'hasAccess': false},
            ],
          }, 200);
        }
        return jsonResponse({
          'data': {
            'id': 'e1',
            'name': 'Ana López',
            'email': 'ana@correo.com',
            'phone': '5512345678',
            'roleId': 'r1',
            'roleName': 'Cajero',
            'isActive': true,
            'cashRegisters': <Object>[],
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: CascaTheme.light,
          home: const Scaffold(body: EmployeeDetailPage(employeeId: 'e1')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(
      tester,
      find.byWidgetPredicate(
        (widget) =>
            widget is CascaCheckbox &&
            widget.semanticLabel == 'Acceso a Caja 1',
      ),
    );
    await _tap(tester, find.widgetWithText(CascaButton, 'Guardar accesos'));
    await _tap(tester, find.widgetWithText(CascaButton, 'Desactivar'));

    final sent = requests.where((request) => request.method == 'PUT').toList();
    expect(sent.map((request) => request.path), [
      EmployeeEndpoints.cashRegisters('e1'),
      EmployeeEndpoints.deactivate('e1'),
    ]);
    expect(sent.first.data, {
      'cashRegisterIds': ['c1'],
    });
    expect(find.text('Empleado desactivado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
