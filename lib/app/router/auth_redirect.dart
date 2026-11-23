import 'package:casca_app/app/router/app_routes.dart';
import 'package:casca_app/core/auth/auth_controller.dart';

String? authRedirect(AuthStatus status, String location) {
  return switch (status) {
    AuthStatus.initializing =>
      location == AppRoutes.splash ? null : AppRoutes.splash,
    AuthStatus.unauthenticated =>
      location == AppRoutes.login ? null : AppRoutes.login,
    AuthStatus.authenticated =>
      location == AppRoutes.login || location == AppRoutes.splash
          ? AppRoutes.home
          : null,
  };
}
