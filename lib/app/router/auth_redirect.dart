import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/routing/app_routes.dart';

String? authRedirect(AuthStatus status, String location) {
  final isGuestRoute = AppRoutes.guestRoutes.contains(location);

  return switch (status) {
    AuthStatus.initializing =>
      location == AppRoutes.splash ? null : AppRoutes.splash,
    AuthStatus.unauthenticated => isGuestRoute ? null : AppRoutes.login,
    AuthStatus.authenticated =>
      isGuestRoute || location == AppRoutes.splash ? AppRoutes.home : null,
  };
}
