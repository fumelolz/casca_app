import 'package:casca_app/app/router/app_router.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/register_request.dart';

import '../../support/fake_auth_repository.dart';

import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(FakeAuthRepository repo) {
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
    await tester.pumpWidget(_app(FakeAuthRepository(hasSession: true)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-page')), findsOneWidget);

    await tester.tap(find.text('X').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('sin sesión abre login', (tester) async {
    await tester.pumpWidget(_app(FakeAuthRepository(hasSession: false)));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  group('recuperar contraseña', () {
    Future<FakeAuthRepository> openForgot(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = FakeAuthRepository(hasSession: false);
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

  group('registro', () {
    Future<FakeAuthRepository> openRegister(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = FakeAuthRepository(hasSession: false);
      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Regístrate'));
      await tester.pumpAndSettle();
      return repo;
    }

    Future<void> pickBusinessType(WidgetTester tester) async {
      await tester.tap(find.text('Selecciona el tipo de negocio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Joyería y platería'));
      await tester.pumpAndSettle();
    }

    Future<void> fillBusiness(
      WidgetTester tester, {
      bool withType = true,
    }) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '  Joyería El Sol ');
      await tester.enterText(fields.at(1), 'María López');
      await tester.enterText(fields.at(2), '5551234567');
      if (withType) await pickBusinessType(tester);
    }

    Future<void> fillAccess(
      WidgetTester tester, {
      String email = 'maria@casca.com',
      String password = 'Abcdef1!',
    }) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(1), password);
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
    }

    testWidgets('abre desde el login y muestra el paso 1', (tester) async {
      await openRegister(tester);

      expect(find.text('PASO 1 DE 2'), findsOneWidget);
      expect(find.text('¡Comencemos con tu negocio!'), findsOneWidget);
    });

    testWidgets('formatea el teléfono con la máscara', (tester) async {
      await openRegister(tester);

      await tester.enterText(find.byType(TextField).at(2), '5551234567');

      final field = tester.widget<TextField>(find.byType(TextField).at(2));
      expect(field.controller!.text, '(555) 123-4567');
    });

    testWidgets('no avanza si falta el tipo de negocio', (tester) async {
      await openRegister(tester);

      await fillBusiness(tester, withType: false);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('PASO 1 DE 2'), findsOneWidget);
    });

    testWidgets('no avanza con un teléfono incompleto', (tester) async {
      await openRegister(tester);

      await fillBusiness(tester);
      await tester.enterText(find.byType(TextField).at(2), '555123');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('PASO 1 DE 2'), findsOneWidget);
    });

    testWidgets('completa el registro y entra a home', (tester) async {
      final repo = await openRegister(tester);

      await fillBusiness(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('PASO 2 DE 2'), findsOneWidget);

      await fillAccess(tester);

      final request = repo.registrations.single;
      expect(request.tenantName, 'Joyería El Sol');
      expect(request.name, 'María López');
      expect(request.phone, '5551234567');
      expect(request.businessType, BusinessType.joyeria);
      expect(request.email, 'maria@casca.com');
      expect(find.byKey(const Key('home-page')), findsOneWidget);
    });

    testWidgets('atrás conserva lo escrito en el paso 1', (tester) async {
      await openRegister(tester);
      await fillBusiness(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Atrás'));
      await tester.pumpAndSettle();

      expect(find.text('PASO 1 DE 2'), findsOneWidget);
      expect(find.text('Joyería y platería'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(field.controller!.text, '  Joyería El Sol ');
    });

    testWidgets('no envía una contraseña débil y dice qué le falta', (
      tester,
    ) async {
      final repo = await openRegister(tester);
      await fillBusiness(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await fillAccess(tester, password: 'abcdefgh');

      expect(repo.registrations, isEmpty);
      expect(
        find.text('Falta: mayúscula, número, carácter especial.'),
        findsOneWidget,
      );
    });

    testWidgets('avisa si el correo ya existe', (tester) async {
      final repo = await openRegister(tester);
      await fillBusiness(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      await fillAccess(tester, email: 'duplicado@casca.com');

      expect(repo.registrations, isEmpty);
      expect(
        find.text('Ya existe una cuenta con ese correo electrónico.'),
        findsOneWidget,
      );
    });

    testWidgets('inicia sesión vuelve al login', (tester) async {
      await openRegister(tester);

      await tester.tap(find.text('Inicia sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsOneWidget);
    });
  });
}
