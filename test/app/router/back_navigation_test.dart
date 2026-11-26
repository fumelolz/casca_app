import 'package:casca_app/app/router/app_router.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/network/fake_http_adapter.dart';
import '../../support/fake_auth_repository.dart';

Future<ProviderContainer> _open(
  WidgetTester tester, {
  bool signedIn = true,
}) async {
  tester.view.physicalSize = Size(signedIn ? 400 : 800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  FlutterSecureStorage.setMockInitialValues({});

  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(
      (_) async => jsonResponse({'data': <Object>[]}, 200),
    );
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(hasSession: signedIn, session: fullAccessSession()),
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
  return container;
}

Future<void> _go(
  WidgetTester tester,
  ProviderContainer container,
  String route,
) async {
  container.read(routerProvider).go(route);
  await tester.pumpAndSettle();
}

Future<bool> _pressBack(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return handled;
}

String _location(ProviderContainer container) {
  return container.read(routerProvider).state.uri.path;
}

void main() {
  testWidgets('atrás recorre las pantallas visitadas y al final sale', (
    tester,
  ) async {
    final container = await _open(tester);
    await _go(tester, container, AppRoutes.preferences);
    await _go(tester, container, AppRoutes.appearance);

    expect(await _pressBack(tester), isTrue);
    expect(_location(container), AppRoutes.preferences);

    expect(await _pressBack(tester), isTrue);
    expect(_location(container), AppRoutes.home);

    expect(await _pressBack(tester), isFalse);
  });

  testWidgets('volver a una pantalla ya visitada no genera ciclos', (
    tester,
  ) async {
    final container = await _open(tester);
    await _go(tester, container, AppRoutes.preferences);
    await _go(tester, container, AppRoutes.appearance);
    await _go(tester, container, AppRoutes.preferences);

    await _pressBack(tester);

    expect(_location(container), AppRoutes.home);
  });

  testWidgets('con el menú abierto atrás solo lo cierra', (tester) async {
    final container = await _open(tester);
    await _go(tester, container, AppRoutes.preferences);
    container.read(sidebarProvider.notifier).openMobile();
    await tester.pumpAndSettle();

    await _pressBack(tester);

    expect(container.read(sidebarProvider).mobileOpen, isFalse);
    expect(_location(container), AppRoutes.preferences);
  });

  testWidgets('en el registro atrás vuelve al inicio de sesión', (
    tester,
  ) async {
    final container = await _open(tester, signedIn: false);
    await _go(tester, container, AppRoutes.register);

    await _pressBack(tester);

    expect(_location(container), AppRoutes.login);
  });
}
