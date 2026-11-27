import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/customers/customer_repository.dart';
import 'package:casca_app/features/customers/presentation/pages/customer_list_page.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
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
  'permissions': ['customer.view', 'customer.create'],
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

Future<List<RequestOptions>> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final requests = <RequestOptions>[];
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter((options) async {
      requests.add(options);
      if (options.method != 'GET') {
        return jsonResponse({
          'data': {
            'confirmationEmailSent': true,
            'id': 'c2',
            'firstName': 'Luis',
            'status': 'Pending',
          },
        }, 200);
      }
      return jsonResponse({
        'data': {
          'items': [
            {
              'id': 'c1',
              'firstName': 'Ana',
              'lastName': 'López',
              'phone': null,
              'email': 'ana@correo.com',
              'notes': null,
              'isActive': true,
              'status': 'Pending',
              'createdOnUtc': '2026-11-26T10:00:00Z',
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
        home: const Scaffold(body: CustomerListPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista clientes y reenvía la confirmación pendiente', (
    tester,
  ) async {
    final requests = await _pump(tester);

    await _tap(tester, find.text('Ana López'));
    await _tap(
      tester,
      find.widgetWithText(CascaButton, 'Reenviar confirmación'),
    );

    expect(
      requests.map((request) => request.path),
      contains(CustomerEndpoints.resendConfirmation('c1')),
    );
    expect(find.text('Se envió la confirmación.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exige un contacto y registra al cliente', (tester) async {
    final requests = await _pump(tester);

    await _tap(tester, find.widgetWithText(CascaButton, 'Registrar cliente'));
    await tester.enterText(find.byType(CascaInput).at(1), ' Luis ');
    await _tap(tester, find.widgetWithText(CascaButton, 'Registrar'));

    expect(
      find.text('Indica al menos un teléfono o un correo.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(CascaInput).at(3), '5512345678');
    await _tap(tester, find.widgetWithText(CascaButton, 'Registrar'));

    final created = requests.singleWhere((request) => request.method == 'POST');
    expect(created.data, {
      'firstName': 'Luis',
      'lastName': null,
      'phone': '5512345678',
      'email': null,
      'notes': null,
    });
    expect(find.text('Registrar'), findsNothing);
  });
}
