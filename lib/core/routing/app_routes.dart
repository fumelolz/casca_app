abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const setPassword = '/set-password';
  static const home = '/home';

  static const guestRoutes = {login, forgotPassword, setPassword};

  static String setPasswordFor({required String email}) {
    return Uri(
      path: setPassword,
      queryParameters: {'email': email, 'recovery': '1'},
    ).toString();
  }
}
