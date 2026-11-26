import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/close_shift_page.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/current_shift_page.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

const _everything = [
  'cashregister.open',
  'cashregister.operate',
  'cashregister.close',
  'cashregister.shifts.view',
];

class _Server {
  _Server({this.open = true, this.registers = 1});

  bool open;
  final int registers;
  String? failure;
  final posts = <RequestOptions>[];

  Future<ResponseBody> handle(RequestOptions options) async {
    if (options.method == 'POST') {
      posts.add(options);
      final failure = this.failure;
      if (failure != null) return jsonResponse({'message': failure}, 400);
      if (options.path.endsWith('/open')) open = true;
      if (options.path.endsWith('/close')) {
        open = false;
        return jsonResponse({
          'data': {
            'cashRegisterShiftId': 't1',
            'countedCash': 1380,
            'difference': -20,
            'totalSales': 1250,
            'withdrawnAtClose': 880,
            'leftInCash': 500,
          },
        }, 200);
      }
      return jsonResponse({'data': null}, 200);
    }

    if (options.path.endsWith('/available')) {
      return jsonResponse({
        'data': [
          for (var index = 1; index <= registers; index++)
            {
              'id': 'c$index',
              'name': 'Caja $index',
              'suggestedInitialAmount': 500,
            },
        ],
      }, 200);
    }

    if (!open) {
      return jsonResponse({
        'errors': [
          {'code': 'CashRegister.NoActiveShift', 'description': 'Sin turno.'},
        ],
      }, 400);
    }

    return jsonResponse({
      'data': {
        'cashRegisterShiftId': 't1',
        'cashRegisterName': 'Caja principal',
        'openedAt': '2026-11-24T15:00:00Z',
        'initialAmount': 500,
        'summary': {
          'cashSales': 900,
          'transferSales': 0,
          'creditCardSales': 0,
          'debitCardSales': 350,
          'cashIn': 0,
          'cashOut': 0,
          'expectedCash': 1400,
          'totalSales': 1250,
        },
      },
    }, 200);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Server server, {
  String location = AppRoutes.currentShift,
  List<String> permissions = _everything,
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
          session: fullAccessSession(permissions: permissions),
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
        path: AppRoutes.currentShift,
        builder: (_, _) => const Scaffold(body: CurrentShiftPage()),
      ),
      GoRoute(
        path: AppRoutes.closeShift,
        builder: (_, _) => const Scaffold(body: CloseShiftPage()),
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

Finder _button(String label) => find.widgetWithText(CascaButton, label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, int field, String text) async {
  await tester.enterText(find.byType(CascaInput).at(field), text);
  await tester.pump();
}

void main() {
  testWidgets('sin turno abre uno con el monto sugerido', (tester) async {
    final server = _Server(open: false);
    await _pump(tester, server);

    await _tap(tester, _button('Abrir turno'));
    expect(find.text('500.00'), findsOneWidget);
    await _tap(tester, _button('Abrir turno').last);

    expect(server.posts.single.path, '/api/v1/cash-registers/c1/open');
    expect(server.posts.single.data, {'initialAmount': 500.0, 'notes': null});
    expect(find.text('Caja principal'), findsOneWidget);
  });

  testWidgets('un monto distinto al sugerido exige el motivo', (tester) async {
    final server = _Server(open: false);
    await _pump(tester, server);
    await _tap(tester, _button('Abrir turno'));

    await _type(tester, 0, '400');
    await _tap(tester, _button('Abrir turno').last);

    expect(find.text('Explica por qué el monto no coincide'), findsOneWidget);
    expect(server.posts, isEmpty);
  });

  testWidgets('con varias cajas pide elegir una', (tester) async {
    final server = _Server(open: false, registers: 2);
    await _pump(tester, server);
    await _tap(tester, _button('Abrir turno'));

    await _tap(tester, _button('Abrir turno').last);

    expect(find.text('Selecciona una caja'), findsWidgets);
    expect(server.posts, isEmpty);
  });

  testWidgets('sin permiso no ofrece abrir turno', (tester) async {
    await _pump(
      tester,
      _Server(open: false),
      permissions: ['cashregister.operate'],
    );

    expect(find.text('No hay un turno activo'), findsOneWidget);
    expect(_button('Abrir turno'), findsNothing);
  });

  testWidgets('muestra el efectivo esperado y despliega su cálculo', (
    tester,
  ) async {
    await _pump(tester, _Server());

    expect(find.text('\$1,400.00'), findsOneWidget);
    expect(find.text('Fondo inicial'), findsNothing);

    await _tap(tester, find.text('Cómo se calcula'));

    expect(find.text('Fondo inicial'), findsOneWidget);
  });

  testWidgets('las acciones dependen de los permisos', (tester) async {
    await _pump(tester, _Server(), permissions: ['cashregister.open']);

    expect(_button('Ingresar'), findsNothing);
    expect(_button('Corte de caja'), findsNothing);
  });

  testWidgets('un retiro exige cantidad y motivo', (tester) async {
    final server = _Server();
    await _pump(tester, server);
    await _tap(tester, _button('Retirar'));

    await _tap(tester, _button('Retirar dinero'));
    expect(find.text('Escribe el motivo'), findsOneWidget);
    expect(server.posts, isEmpty);

    await _type(tester, 0, '100');
    await _type(tester, 1, 'Pago a proveedor');
    await _tap(tester, _button('Retirar dinero'));

    expect(
      server.posts.single.path,
      '/api/v1/cash-registers/shifts/t1/cash-movements/withdrawal',
    );
    expect(server.posts.single.data, {
      'amount': 100.0,
      'notes': 'Pago a proveedor',
    });
    expect(find.byType(CascaInput), findsNothing);
  });

  testWidgets('un ingreso rechazado muestra el motivo del servidor', (
    tester,
  ) async {
    final server = _Server()..failure = 'La sesión de caja está cerrada';
    await _pump(tester, server);
    await _tap(tester, _button('Ingresar'));

    await _type(tester, 0, '100');
    await _type(tester, 1, 'Cambio');
    await _tap(tester, _button('Ingresar dinero'));

    expect(find.text('La sesión de caja está cerrada'), findsOneWidget);
  });

  testWidgets('el corte exige contar y explicar la diferencia', (tester) async {
    final server = _Server();
    await _pump(tester, server, location: AppRoutes.closeShift);

    await _tap(tester, _button('Continuar'));
    expect(find.text('Captura lo que contaste'), findsNWidgets(2));

    await _type(tester, 0, '1380');
    await _type(tester, 2, '350');
    expect(find.text('Faltan \$20.00'), findsOneWidget);
    await _tap(tester, _button('Continuar'));

    expect(find.text('Explica el motivo de la diferencia'), findsOneWidget);
    expect(_button('Confirmar corte'), findsNothing);
  });

  testWidgets('cierra el turno en dos pasos y muestra el resultado', (
    tester,
  ) async {
    final server = _Server();
    await _pump(tester, server);
    await _tap(tester, _button('Corte de caja'));

    await _type(tester, 0, '1380');
    await _type(tester, 2, '350');
    await _type(tester, 4, 'Faltó cambio');
    await _tap(tester, _button('Continuar'));
    expect(find.text('1380.00'), findsOneWidget);

    await _type(tester, 0, '880');
    expect(find.text('\$500.00'), findsOneWidget);
    await _tap(tester, _button('Confirmar corte'));

    expect(server.posts.single.path, '/api/v1/cash-registers/shifts/t1/close');
    expect(server.posts.single.data, {
      'countedCash': 1380.0,
      'notes': 'Faltó cambio',
      'withdrawnAtClose': 880.0,
      'paymentCounts': [
        {'method': 3, 'countedAmount': 350.0},
      ],
    });
    expect(find.text('Turno cerrado'), findsOneWidget);
    expect(_button('Ver detalle del turno'), findsOneWidget);

    await _tap(tester, _button('Listo'));

    expect(find.text('No hay un turno activo'), findsOneWidget);
  });

  testWidgets('no permite retirar más de lo contado', (tester) async {
    final server = _Server();
    await _pump(tester, server, location: AppRoutes.closeShift);
    await _type(tester, 0, '1400');
    await _type(tester, 2, '350');
    await _tap(tester, _button('Continuar'));

    await _type(tester, 0, '1500');
    await _tap(tester, _button('Confirmar corte'));

    expect(
      find.text('Escribe una cantidad entre 0 y \$1,400.00'),
      findsOneWidget,
    );
    expect(server.posts, isEmpty);
  });

  testWidgets('si el corte falla conserva lo capturado', (tester) async {
    final server = _Server()..failure = 'La diferencia supera el 50%.';
    await _pump(tester, server, location: AppRoutes.closeShift);
    await _type(tester, 0, '1400');
    await _type(tester, 2, '350');
    await _tap(tester, _button('Continuar'));

    await _tap(tester, _button('Confirmar corte'));

    expect(find.text('La diferencia supera el 50%.'), findsOneWidget);
    await _tap(tester, _button('Volver'));
    expect(find.text('1400'), findsOneWidget);
  });

  for (final location in [AppRoutes.currentShift, AppRoutes.closeShift]) {
    testWidgets('en teléfono no desborda: $location', (tester) async {
      await _pump(tester, _Server(), location: location, width: 360);

      expect(tester.takeException(), isNull);
    });
  }
}
