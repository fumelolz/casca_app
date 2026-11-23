import 'package:casca_app/app/router/app_router.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

SessionState _session() => SessionState.fromJson({
  'account': {'id': 'a1', 'email': 'x@y.com', 'name': 'X'},
  'roles': [],
  'hasTenant': false,
  'hasCompletedOnboarding': false,
});

class _FakeRepo implements AuthRepository {
  _FakeRepo({required this.hasSession});

  bool hasSession;

  @override
  Future<SessionState> me() async {
    if (!hasSession) throw const ApiException(type: ApiErrorType.unauthorized);
    return _session();
  }

  @override
  Future<SessionState> login({
    required String email,
    required String password,
  }) async {
    hasSession = true;
    return _session();
  }

  @override
  Future<void> logout() async => hasSession = false;

  @override
  Future<void> forgotPassword({required String email}) async {}
}

Widget _app(_FakeRepo repo) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        theme: CascaTheme.light,
        routerConfig: ref.watch(routerProvider),
      ),
    ),
  );
}

void main() {
  testWidgets('con sesión válida abre home y cerrar sesión vuelve a login', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_FakeRepo(hasSession: true)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('sin sesión abre login', (tester) async {
    await tester.pumpWidget(_app(_FakeRepo(hasSession: false)));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
