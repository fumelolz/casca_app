import 'package:casca_app/app/router/app_routes.dart';
import 'package:casca_app/app/router/auth_redirect.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('initializing', () {
    test('manda a splash desde cualquier ruta', () {
      expect(
        authRedirect(AuthStatus.initializing, AppRoutes.home),
        AppRoutes.splash,
      );
      expect(
        authRedirect(AuthStatus.initializing, AppRoutes.login),
        AppRoutes.splash,
      );
    });

    test('se queda en splash', () {
      expect(authRedirect(AuthStatus.initializing, AppRoutes.splash), isNull);
    });
  });

  group('unauthenticated', () {
    test('manda a login desde splash y home', () {
      expect(
        authRedirect(AuthStatus.unauthenticated, AppRoutes.splash),
        AppRoutes.login,
      );
      expect(
        authRedirect(AuthStatus.unauthenticated, AppRoutes.home),
        AppRoutes.login,
      );
    });

    test('se queda en login', () {
      expect(authRedirect(AuthStatus.unauthenticated, AppRoutes.login), isNull);
    });
  });

  group('authenticated', () {
    test('saca de login y splash hacia home', () {
      expect(
        authRedirect(AuthStatus.authenticated, AppRoutes.login),
        AppRoutes.home,
      );
      expect(
        authRedirect(AuthStatus.authenticated, AppRoutes.splash),
        AppRoutes.home,
      );
    });

    test('se queda en home', () {
      expect(authRedirect(AuthStatus.authenticated, AppRoutes.home), isNull);
    });
  });
}
