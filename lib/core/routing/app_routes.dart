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
  static const customers = '/customers';
  static const employees = '/employees';
  static const employeeDetail = '/employees/:employeeId';
  static const roles = '/roles';
  static const roleNew = '/roles/new';
  static const roleDetail = '/roles/:roleId';
  static const roleCopyParameter = 'copiarDe';
  static const printers = '/printers';
  static const printerTabParameter = 'tipo';
  static const labelPrinters = '$printers?$printerTabParameter=etiquetas';
  static const cashRegisters = '/cash-register/registers';

  static const sales = '/sales';
  static const saleDetail = '/sales/:saleId';
  static const saleShiftParameter = 'turno';

  static const priceLists = '/price-lists';
  static const priceListDetail = '/price-lists/:priceListId';

  static const currentShift = '/cash-register/current-shift';
  static const closeShift = '/cash-register/current-shift/close';

  static const shiftHistory = '/cash-register/shift-history';
  static const shiftDetail = '/cash-register/shift-history/:shiftId';

  static const guestRoutes = {login, forgotPassword, setPassword, register};

  static String shiftDetailFor(String shiftId) => '$shiftHistory/$shiftId';

  static String saleDetailFor(String saleId, {String? shiftId}) {
    return Uri(
      path: '$sales/$saleId',
      queryParameters: shiftId == null ? null : {saleShiftParameter: shiftId},
    ).toString();
  }

  static String employeeFor(String employeeId) => '$employees/$employeeId';

  static String roleFor(String roleId) => '$roles/$roleId';

  static String roleCopyOf(String roleId) {
    return '$roleNew?$roleCopyParameter=$roleId';
  }

  static String priceListFor(String priceListId) => '$priceLists/$priceListId';

  static String productEditFor(String productId) => '/products/$productId/edit';

  static bool isFormRoute(String location) {
    return location == productNew ||
        location == closeShift ||
        RegExp(r'^/products/[^/]+/edit$').hasMatch(location) ||
        RegExp(r'^/price-lists/[^/]+$').hasMatch(location) ||
        RegExp(r'^/roles/[^/]+$').hasMatch(location);
  }

  static String setPasswordFor({required String email}) {
    return Uri(
      path: setPassword,
      queryParameters: {'email': email, 'recovery': '1'},
    ).toString();
  }
}
