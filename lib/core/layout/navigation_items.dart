import 'package:casca_app/core/layout/navigation_item.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';

const shiftWorkPermissions = [
  'cashregister.open',
  'cashregister.close',
  'cashregister.operate',
];

const navigationModules = [
  NavigationItem(
    id: 'dashboard',
    label: 'Inicio',
    icon: CascaIcons.house,
    route: AppRoutes.home,
    section: 'Principal',
    permission: 'dashboard.view',
  ),
  NavigationItem(
    id: 'pos',
    label: 'Vender',
    icon: CascaIcons.cashRegister,
    route: '/pos',
    section: 'Principal',
    permission: 'sale.create',
  ),
  NavigationItem(
    id: 'sales-history',
    label: 'Ventas realizadas',
    icon: CascaIcons.receipt,
    route: '/sales',
    section: 'Principal',
    permission: 'sale.view',
  ),
  NavigationItem(
    id: 'customers',
    label: 'Clientes',
    icon: CascaIcons.addressBook,
    route: '/customers',
    section: 'Principal',
    permission: 'customer.view',
  ),
  NavigationItem(
    id: 'cash-register',
    label: 'Control de caja',
    icon: CascaIcons.wallet,
    section: 'Operación',
    children: [
      NavigationItem(
        id: 'cash-register-current-shift',
        label: 'Turno actual',
        icon: CascaIcons.clock,
        route: '/cash-register/current-shift',
        anyPermission: shiftWorkPermissions,
      ),
      NavigationItem(
        id: 'shift-history',
        label: 'Historial de turnos',
        icon: CascaIcons.clockRotateLeft,
        route: '/cash-register/shift-history',
        permission: 'cashregister.shifts.view',
      ),
    ],
  ),
  NavigationItem(
    id: 'products',
    label: 'Productos',
    icon: CascaIcons.cube,
    section: 'Catálogo',
    route: AppRoutes.products,
    permission: 'product.view',
  ),
  NavigationItem(
    id: 'reports',
    label: 'Resumen de reportes',
    icon: CascaIcons.chartColumn,
    route: '/reports',
    section: 'Reportes',
    anyPermission: ['inventory.review'],
  ),
];

const preferenceModules = [
  NavigationItem(
    id: 'online-catalog',
    label: 'Catálogo en línea',
    icon: CascaIcons.globe,
    route: '/online-catalog',
    permission: 'store.view',
  ),
  NavigationItem(
    id: 'printers',
    label: 'Impresoras',
    icon: CascaIcons.print,
    route: '/printers',
    permission: 'sale.create',
  ),
  NavigationItem(
    id: 'inventory-count-settings',
    label: 'Conteos de inventario',
    icon: CascaIcons.clipboardList,
    route: '/inventory-counts/settings',
    permission: 'inventory.approve',
  ),
  NavigationItem(
    id: 'appearance',
    label: 'Apariencia',
    icon: CascaIcons.palette,
    route: '/appearance',
  ),
  NavigationItem(
    id: 'cash-register-list',
    label: 'Cajas registradoras',
    icon: CascaIcons.cashRegister,
    route: '/cash-register/registers',
    permission: 'cashregister.view',
  ),
  NavigationItem(
    id: 'price-lists',
    label: 'Listas de precios',
    icon: CascaIcons.tags,
    route: '/price-lists',
    permission: 'pricelist.view',
  ),
  NavigationItem(
    id: 'categories-list',
    label: 'Categorías de productos',
    icon: CascaIcons.list,
    route: AppRoutes.productCategories,
    permission: 'category.view',
  ),
  NavigationItem(
    id: 'businesses',
    label: 'Negocios',
    icon: CascaIcons.building,
    route: '/businesses',
    section: 'Organización',
  ),
  NavigationItem(
    id: 'stores',
    label: 'Sucursales',
    icon: CascaIcons.store,
    route: '/stores',
    section: 'Organización',
    permission: 'store.view',
  ),
  NavigationItem(
    id: 'employees',
    label: 'Empleados',
    icon: CascaIcons.users,
    route: '/employees',
    section: 'Organización',
    permission: 'storeuser.view',
  ),
  NavigationItem(
    id: 'roles',
    label: 'Roles',
    icon: CascaIcons.userShield,
    route: '/roles',
    section: 'Organización',
    permission: 'role.view',
  ),
];

List<NavigationItem> get allNavigationRoutes {
  return [
    for (final item in [...navigationModules, ...preferenceModules])
      if (item.hasChildren) ...item.children! else item,
  ].where((item) => item.route != null).toList();
}

const posTabId = 'tab-pos';

const mobileTabModules = [
  NavigationItem(
    id: 'tab-dashboard',
    label: 'Inicio',
    icon: CascaIcons.house,
    route: AppRoutes.home,
    permission: 'dashboard.view',
  ),
  NavigationItem(
    id: 'tab-sales',
    label: 'Ventas',
    icon: CascaIcons.receipt,
    route: '/sales',
    permission: 'sale.view',
  ),
  NavigationItem(
    id: posTabId,
    label: 'Vender',
    icon: CascaIcons.cashRegister,
    route: '/pos',
    permission: 'sale.create',
  ),
  NavigationItem(
    id: 'tab-cash-register',
    label: 'Caja',
    icon: CascaIcons.wallet,
    route: '/cash-register/current-shift',
    anyPermission: shiftWorkPermissions,
    matchPrefixes: [
      '/cash-register/current-shift',
      '/cash-register/shift-history',
    ],
  ),
  NavigationItem(
    id: 'tab-products',
    label: 'Productos',
    icon: CascaIcons.cube,
    route: '/products',
    permission: 'product.view',
  ),
];
