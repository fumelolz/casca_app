abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const setPassword = '/set-password';
  static const register = '/register';
  static const home = '/home';
  static const pos = '/pos';
  static const businesses = '/businesses';
  static const preferences = '/preferences';
  static const products = '/products';
  static const productNew = '/products/new';
  static const productEdit = '/products/:productId/edit';
  static const productCategories = '/categories';
  static const stores = '/stores';
  static const appearance = '/appearance';
  static const cashRegisters = '/cash-register/registers';

  static const priceLists = '/price-lists';
  static const priceListDetail = '/price-lists/:priceListId';

  static const guestRoutes = {login, forgotPassword, setPassword, register};

  static String priceListFor(String priceListId) => '$priceLists/$priceListId';

  static String productEditFor(String productId) => '/products/$productId/edit';

  static bool isFormRoute(String location) {
    return location == productNew ||
        RegExp(r'^/products/[^/]+/edit$').hasMatch(location) ||
        RegExp(r'^/price-lists/[^/]+$').hasMatch(location);
  }

  static String setPasswordFor({required String email}) {
    return Uri(
      path: setPassword,
      queryParameters: {'email': email, 'recovery': '1'},
    ).toString();
  }
}
