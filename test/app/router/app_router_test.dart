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

  final requestedEmails = <String>[];
  final passwordChanges = <String>[];

  @override
  Future<void> forgotPassword({required String email}) async {
    requestedEmails.add(email);
  }

  @override
  Future<String> verifyResetCode({
    required String email,
    required String code,
  }) async {
    if (code != '123456') {
      throw const ApiException(
        type: ApiErrorType.client,
        serverMessage: 'El código no es válido.',
      );
    }
    return 'token-$email';
  }

  @override
  Future<void> changePassword({
    required String sessionToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    passwordChanges.add('$sessionToken|$newPassword');
  }
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

  group('recuperar contraseña', () {
    Future<_FakeRepo> openForgot(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = _FakeRepo(hasSession: false);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      return repo;
    }

    Future<void> requestCode(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'A@B.com');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya tengo mi código'));
      await tester.pumpAndSettle();
    }

    Future<void> fillReset(
      WidgetTester tester, {
      String code = '123456',
      String password = 'Abcdef1!',
    }) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), code);
      await tester.enterText(fields.at(1), password);
      await tester.tap(find.text('Restablecer contraseña'));
      await tester.pumpAndSettle();
    }

    testWidgets('pide el código con el correo normalizado', (tester) async {
      final repo = await openForgot(tester);
      expect(find.text('Recupera tu contraseña'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'A@B.com');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      expect(find.text('Revisa tu correo'), findsOneWidget);
      expect(repo.requestedEmails, ['a@b.com']);
    });

    testWidgets('no envía si el correo es inválido', (tester) async {
      final repo = await openForgot(tester);

      await tester.enterText(find.byType(TextField), 'sin-arroba');
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      expect(repo.requestedEmails, isEmpty);
      expect(find.text('Revisa tu correo'), findsNothing);
    });

    testWidgets('completa el flujo y deja la contraseña lista', (tester) async {
      final repo = await openForgot(tester);
      await requestCode(tester);

      expect(find.text('Elige tu contraseña nueva'), findsOneWidget);
      expect(find.textContaining('a@b.com'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));

      await fillReset(tester);

      expect(find.text('Contraseña lista'), findsOneWidget);
      expect(repo.passwordChanges, ['token-a@b.com|Abcdef1!']);

      await tester.tap(find.text('Ir a iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('no envía una contraseña débil y dice qué le falta', (
      tester,
    ) async {
      final repo = await openForgot(tester);
      await requestCode(tester);

      await fillReset(tester, password: 'abcdefgh');

      expect(repo.passwordChanges, isEmpty);
      expect(
        find.text('Falta: mayúscula, número, carácter especial.'),
        findsOneWidget,
      );
    });

    testWidgets('limita el código a 6 dígitos', (tester) async {
      await openForgot(tester);
      await requestCode(tester);

      await tester.enterText(find.byType(TextField).at(0), '12345678');

      final field = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(field.controller!.text, '123456');
    });

    testWidgets('muestra el mensaje del servidor si el código es inválido', (
      tester,
    ) async {
      final repo = await openForgot(tester);
      await requestCode(tester);

      await fillReset(tester, code: '000000');

      expect(find.text('El código no es válido.'), findsOneWidget);
      expect(repo.passwordChanges, isEmpty);
    });
  });
}
