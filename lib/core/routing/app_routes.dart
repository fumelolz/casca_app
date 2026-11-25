abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const setPassword = '/set-password';
  static const register = '/register';
  static const home = '/home';
  static const businesses = '/businesses';
  static const preferences = '/preferences';
  static const products = '/products';
  static const productNew = '/products/new';
  static const productEdit = '/products/:productId/edit';
  static const productCategories = '/categories';
  static const stores = '/stores';
  static const appearance = '/appearance';
  static const cashRegisters = '/cash-register/registers';

  static const guestRoutes = {login, forgotPassword, setPassword, register};

  static String productEditFor(String productId) => '/products/$productId/edit';

  static bool isFormRoute(String location) {
    return location == productNew ||
        RegExp(r'^/products/[^/]+/edit$').hasMatch(location);
  }

  static String setPasswordFor({required String email}) {
    return Uri(
      path: setPassword,
      queryParameters: {'email': email, 'recovery': '1'},
    ).toString();
  }
}
