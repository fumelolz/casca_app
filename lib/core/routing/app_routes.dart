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
  static const productCategories = '/products/categories';

  static const guestRoutes = {login, forgotPassword, setPassword, register};

  static String setPasswordFor({required String email}) {
    return Uri(
      path: setPassword,
      queryParameters: {'email': email, 'recovery': '1'},
    ).toString();
  }
}
