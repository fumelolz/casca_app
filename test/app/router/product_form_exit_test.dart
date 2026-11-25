import 'package:casca_app/app/router/app_router.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/layout/mobile_bottom_bar.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/auth/presentation/pages/login_page.dart';
import 'package:casca_app/features/products/presentation/pages/product_form_page.dart';
import 'package:casca_app/features/products/presentation/pages/product_list_page.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

const _discardTitle = '¿Descartar cambios?';
const _navigationInset = 30.0;

Future<ResponseBody> _emptyPage(RequestOptions options) async {
  return jsonResponse({
    'data': {
      'items': <Object>[],
      'page': 1,
      'pageSize': 10,
      'totalCount': 0,
      'totalPages': 0,
      'hasNextPage': false,
      'hasPreviousPage': false,
    },
  }, 200);
}

Future<ProviderContainer> _openForm(
  WidgetTester tester, {
  double keyboard = 0,
}) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: _navigationInset);
  tester.view.viewPadding = const FakeViewPadding(bottom: _navigationInset);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({});

  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(_emptyPage);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(hasSession: true, session: fullAccessSession()),
      ),
      apiClientProvider.overrideWithValue(ApiClient(dio, CookieJar())),
      cookieJarProvider.overrideWithValue(CookieJar()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: CascaTheme.light,
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  container.read(routerProvider).go(AppRoutes.productNew);
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> _typeName(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).first, 'Arroz');
  await tester.pump();
}

void main() {
  testWidgets('el formulario oculta la barra inferior', (tester) async {
    await _openForm(tester);

    expect(find.byType(ProductFormPage), findsOneWidget);
    expect(find.byType(MobileBottomBar), findsNothing);

    await _tap(tester, 'Cancelar');

    expect(find.byType(MobileBottomBar), findsOneWidget);
  });

  testWidgets('el pie respeta la barra de navegación del sistema', (
    tester,
  ) async {
    await _openForm(tester);

    final footer = tester.getRect(find.byKey(const Key('product-form-footer')));

    expect(footer.bottom, 1000);
    expect(
      tester.getBottomLeft(find.text('Cancelar')).dy,
      lessThanOrEqualTo(1000 - _navigationInset),
    );
  });

  testWidgets('el pie queda arriba del teclado', (tester) async {
    await _openForm(tester, keyboard: 300);

    final footer = tester.getRect(find.byKey(const Key('product-form-footer')));

    expect(footer.bottom, 700);
  });

  testWidgets('sin cambios, cancelar sale sin preguntar', (tester) async {
    await _openForm(tester);

    await _tap(tester, 'Cancelar');

    expect(find.text(_discardTitle), findsNothing);
    expect(find.byType(ProductListPage), findsOneWidget);
  });

  testWidgets('con cambios pregunta y permite seguir editando', (tester) async {
    await _openForm(tester);
    await _typeName(tester);

    await _tap(tester, 'Cancelar');
    expect(find.text(_discardTitle), findsOneWidget);

    await _tap(tester, 'Seguir editando');

    expect(find.byType(ProductFormPage), findsOneWidget);
    expect(find.text('Arroz'), findsOneWidget);
  });

  testWidgets('al descartar sale del formulario', (tester) async {
    await _openForm(tester);
    await _typeName(tester);
    await _tap(tester, 'Cancelar');

    await _tap(tester, 'Descartar');

    expect(find.byType(ProductListPage), findsOneWidget);
  });

  testWidgets('el botón atrás vuelve a la lista', (tester) async {
    await _openForm(tester);

    await _pressBack(tester);

    expect(find.byType(ProductListPage), findsOneWidget);
  });

  testWidgets('el botón atrás con cambios también pregunta', (tester) async {
    await _openForm(tester);
    await _typeName(tester);

    await _pressBack(tester);
    expect(find.text(_discardTitle), findsOneWidget);

    await _pressBack(tester);

    expect(find.text(_discardTitle), findsNothing);
    expect(find.byType(ProductFormPage), findsOneWidget);
  });

  testWidgets('si la sesión termina sale sin preguntar', (tester) async {
    final container = await _openForm(tester);
    await _typeName(tester);

    await container.read(authControllerProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(find.text(_discardTitle), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
