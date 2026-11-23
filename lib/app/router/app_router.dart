import 'package:casca_app/app/router/auth_redirect.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:casca_app/features/auth/presentation/pages/login_page.dart';
import 'package:casca_app/features/auth/presentation/pages/set_password_page.dart';
import 'package:casca_app/features/auth/presentation/pages/splash_page.dart';
import 'package:casca_app/features/home/presentation/pages/home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _AuthRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.listen(authControllerProvider, (previous, next) => refresh.notify());

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      ref.read(authControllerProvider).status,
      state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.setPassword,
        builder: (context, state) => SetPasswordPage(
          email: state.uri.queryParameters['email'] ?? '',
          recovery: state.uri.queryParameters['recovery'] == '1',
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
