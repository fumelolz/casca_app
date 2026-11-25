import 'package:casca_app/app/router/auth_redirect.dart';
import 'package:casca_app/app/router/module_placeholder_page.dart';
import 'package:casca_app/app/router/shell_page.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/layout/app_shell.dart';
import 'package:casca_app/core/layout/navigation_items.dart';
import 'package:casca_app/core/layout/preferences_hub_page.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/appearance/presentation/pages/appearance_page.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/cash_register_list_page.dart';
import 'package:casca_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:casca_app/features/auth/presentation/pages/login_page.dart';
import 'package:casca_app/features/auth/presentation/pages/register_page.dart';
import 'package:casca_app/features/auth/presentation/pages/set_password_page.dart';
import 'package:casca_app/features/auth/presentation/pages/splash_page.dart';
import 'package:casca_app/features/products/presentation/pages/category_list_page.dart';
import 'package:casca_app/features/products/presentation/pages/product_list_page.dart';
import 'package:casca_app/features/stores/presentation/pages/store_list_page.dart';
import 'package:casca_app/features/home/presentation/pages/home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _AuthRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _placeholderRoutes = allNavigationRoutes
    .where(
      (item) =>
          item.route != AppRoutes.home &&
          item.route != AppRoutes.products &&
          item.route != AppRoutes.stores &&
          item.route != AppRoutes.appearance &&
          item.route != AppRoutes.cashRegisters &&
          item.route != AppRoutes.productCategories,
    )
    .toList();

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
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => shellPage(state, const HomePage()),
          ),
          GoRoute(
            path: AppRoutes.preferences,
            pageBuilder: (context, state) =>
                shellPage(state, const PreferencesHubPage()),
          ),
          GoRoute(
            path: AppRoutes.productCategories,
            pageBuilder: (context, state) =>
                shellPage(state, const CategoryListPage()),
          ),
          GoRoute(
            path: AppRoutes.products,
            pageBuilder: (context, state) =>
                shellPage(state, const ProductListPage()),
          ),
          GoRoute(
            path: AppRoutes.cashRegisters,
            pageBuilder: (context, state) =>
                shellPage(state, const CashRegisterListPage()),
          ),
          GoRoute(
            path: AppRoutes.stores,
            pageBuilder: (context, state) =>
                shellPage(state, const StoreListPage()),
          ),
          GoRoute(
            path: AppRoutes.appearance,
            pageBuilder: (context, state) =>
                shellPage(state, const AppearancePage()),
          ),
          for (final item in _placeholderRoutes)
            GoRoute(
              path: item.route!,
              pageBuilder: (context, state) =>
                  shellPage(state, ModulePlaceholderPage(title: item.label)),
            ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
