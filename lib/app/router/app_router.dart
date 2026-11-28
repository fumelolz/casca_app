import 'package:casca_app/app/router/auth_redirect.dart';
import 'package:casca_app/app/router/confirm_discard.dart';
import 'package:casca_app/app/router/module_placeholder_page.dart';
import 'package:casca_app/app/router/shell_page.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/layout/app_shell.dart';
import 'package:casca_app/core/layout/navigation_items.dart';
import 'package:casca_app/core/layout/preferences_hub_page.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/appearance/presentation/pages/appearance_page.dart';
import 'package:casca_app/features/businesses/presentation/pages/business_list_page.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/cash_register_list_page.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/close_shift_page.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/current_shift_page.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/shift_detail_page.dart';
import 'package:casca_app/features/cash_registers/presentation/pages/shift_history_page.dart';
import 'package:casca_app/features/customers/presentation/pages/customer_list_page.dart';
import 'package:casca_app/features/employees/presentation/pages/employee_detail_page.dart';
import 'package:casca_app/features/employees/presentation/pages/employee_list_page.dart';
import 'package:casca_app/features/roles/presentation/pages/role_editor_page.dart';
import 'package:casca_app/features/roles/presentation/pages/role_list_page.dart';
import 'package:casca_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:casca_app/features/auth/presentation/pages/login_page.dart';
import 'package:casca_app/features/auth/presentation/pages/register_page.dart';
import 'package:casca_app/features/auth/presentation/pages/set_password_page.dart';
import 'package:casca_app/features/auth/presentation/pages/splash_page.dart';
import 'package:casca_app/features/pos/presentation/pages/pos_page.dart';
import 'package:casca_app/features/price_lists/presentation/pages/price_list_detail_page.dart';
import 'package:casca_app/features/price_lists/presentation/pages/price_list_page.dart';
import 'package:casca_app/features/printers/presentation/pages/printer_settings_page.dart';
import 'package:casca_app/features/printers/presentation/providers/printer_scan_provider.dart';
import 'package:casca_app/features/products/presentation/pages/category_list_page.dart';
import 'package:casca_app/features/products/presentation/pages/product_detail_page.dart';
import 'package:casca_app/features/products/presentation/pages/product_form_page.dart';
import 'package:casca_app/features/products/presentation/pages/product_list_page.dart';
import 'package:casca_app/features/sales/presentation/pages/sale_detail_page.dart';
import 'package:casca_app/features/sales/presentation/pages/sales_history_page.dart';
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
          item.route != AppRoutes.pos &&
          item.route != AppRoutes.businesses &&
          item.route != AppRoutes.sales &&
          item.route != AppRoutes.currentShift &&
          item.route != AppRoutes.shiftHistory &&
          item.route != AppRoutes.priceLists &&
          item.route != AppRoutes.products &&
          item.route != AppRoutes.stores &&
          item.route != AppRoutes.appearance &&
          item.route != AppRoutes.printers &&
          item.route != AppRoutes.customers &&
          item.route != AppRoutes.employees &&
          item.route != AppRoutes.roles &&
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
            path: AppRoutes.pos,
            pageBuilder: (context, state) => shellPage(state, const PosPage()),
          ),
          GoRoute(
            path: AppRoutes.businesses,
            pageBuilder: (context, state) =>
                shellPage(state, const BusinessListPage()),
          ),
          GoRoute(
            path: AppRoutes.sales,
            pageBuilder: (context, state) =>
                shellPage(state, const SalesHistoryPage()),
          ),
          GoRoute(
            path: AppRoutes.saleDetail,
            pageBuilder: (context, state) => shellPage(
              state,
              SaleDetailPage(
                saleId: state.pathParameters['saleId']!,
                shiftId:
                    state.uri.queryParameters[AppRoutes.saleShiftParameter],
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.priceLists,
            pageBuilder: (context, state) =>
                shellPage(state, const PriceListPage()),
          ),
          GoRoute(
            path: AppRoutes.priceListDetail,
            onExit: confirmDiscard(ref),
            pageBuilder: (context, state) => shellPage(
              state,
              PriceListDetailPage(
                priceListId: state.pathParameters['priceListId']!,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.currentShift,
            pageBuilder: (context, state) =>
                shellPage(state, const CurrentShiftPage()),
          ),
          GoRoute(
            path: AppRoutes.closeShift,
            onExit: confirmDiscard(ref),
            pageBuilder: (context, state) =>
                shellPage(state, const CloseShiftPage()),
          ),
          GoRoute(
            path: AppRoutes.shiftHistory,
            pageBuilder: (context, state) =>
                shellPage(state, const ShiftHistoryPage()),
          ),
          GoRoute(
            path: AppRoutes.shiftDetail,
            pageBuilder: (context, state) => shellPage(
              state,
              ShiftDetailPage(shiftId: state.pathParameters['shiftId']!),
            ),
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
          GoRoute(
            path: AppRoutes.employees,
            pageBuilder: (context, state) =>
                shellPage(state, const EmployeeListPage()),
          ),
          GoRoute(
            path: AppRoutes.employeeDetail,
            pageBuilder: (context, state) => shellPage(
              state,
              EmployeeDetailPage(
                employeeId: state.pathParameters['employeeId']!,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.roles,
            pageBuilder: (context, state) =>
                shellPage(state, const RoleListPage()),
          ),
          GoRoute(
            path: AppRoutes.roleNew,
            onExit: confirmDiscard(ref),
            pageBuilder: (context, state) {
              final copyFrom =
                  state.uri.queryParameters[AppRoutes.roleCopyParameter];
              return shellPage(
                state,
                RoleEditorPage(
                  key: ValueKey('nuevo-$copyFrom'),
                  copyFrom: copyFrom,
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.roleDetail,
            onExit: confirmDiscard(ref),
            pageBuilder: (context, state) {
              final roleId = state.pathParameters['roleId']!;
              return shellPage(
                state,
                RoleEditorPage(key: ValueKey(roleId), roleId: roleId),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.customers,
            pageBuilder: (context, state) =>
                shellPage(state, const CustomerListPage()),
          ),
          GoRoute(
            path: AppRoutes.printers,
            pageBuilder: (context, state) => shellPage(
              state,
              PrinterSettingsPage(
                initialTab: state.uri.toString() == AppRoutes.labelPrinters
                    ? PrinterTab.labels
                    : PrinterTab.tickets,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.productNew,
            onExit: confirmDiscard(ref),
            pageBuilder: (context, state) =>
                shellPage(state, const ProductFormPage()),
          ),
          GoRoute(
            path: AppRoutes.productEdit,
            onExit: confirmDiscard(ref),
            pageBuilder: (context, state) => shellPage(
              state,
              ProductFormPage(productId: state.pathParameters['productId']),
            ),
          ),
          GoRoute(
            path: AppRoutes.productDetail,
            pageBuilder: (context, state) => shellPage(
              state,
              ProductDetailPage(productId: state.pathParameters['productId']!),
            ),
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
