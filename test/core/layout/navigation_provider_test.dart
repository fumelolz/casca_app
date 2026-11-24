import 'package:casca_app/core/layout/navigation_item.dart';
import 'package:casca_app/core/layout/navigation_items.dart';
import 'package:casca_app/core/layout/navigation_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';

List<String> _labels(NavigationState nav) {
  return [
    for (final section in nav.sections)
      for (final item in section.items) item.label,
  ];
}

void main() {
  group('buildNavigation', () {
    test('sin sesión no muestra ningún módulo', () {
      final nav = buildNavigation(null);

      expect(nav.sections, isEmpty);
      expect(nav.preferences, isEmpty);
    });

    test('con todos los permisos muestra los módulos y sus secciones', () {
      final nav = buildNavigation(fullAccessSession());

      expect(nav.sections.map((s) => s.label), [
        'Principal',
        'Operación',
        'Catálogo',
        'Reportes',
      ]);
      expect(_labels(nav), [
        'Inicio',
        'Vender',
        'Ventas realizadas',
        'Clientes',
        'Control de caja',
        'Productos',
        'Resumen de reportes',
      ]);
    });

    test('oculta los módulos para los que no hay permiso', () {
      final nav = buildNavigation(
        fullAccessSession(permissions: ['sale.view', 'product.view']),
      );

      expect(_labels(nav), ['Ventas realizadas', 'Productos']);
    });

    test('un grupo solo conserva los hijos permitidos', () {
      final nav = buildNavigation(
        fullAccessSession(permissions: ['product.view']),
      );

      final products = nav.sections.single.items.single;
      expect(products.children!.map((c) => c.label), ['Lista de productos']);
    });

    test('un grupo sin hijos visibles se oculta', () {
      final nav = buildNavigation(fullAccessSession(permissions: ['x']));

      expect(_labels(nav), isEmpty);
    });

    test('anyPermission basta con tener uno de los permisos', () {
      final nav = buildNavigation(
        fullAccessSession(permissions: ['cashregister.operate']),
      );

      final cash = nav.sections.single.items.single;
      expect(cash.label, 'Control de caja');
      expect(cash.children!.map((c) => c.label), ['Turno actual']);
    });

    test('las preferencias sin permiso siempre aparecen', () {
      final nav = buildNavigation(fullAccessSession(permissions: ['x']));

      expect(nav.preferences.map((p) => p.label), ['Apariencia', 'Negocios']);
      expect(nav.preferenceGroups.map((g) => g.label), ['', 'Organización']);
    });

    test('agrupa las preferencias por sección', () {
      final nav = buildNavigation(fullAccessSession());

      final organization = nav.preferenceGroups.last;
      expect(organization.label, 'Organización');
      expect(organization.items.map((i) => i.label), [
        'Negocios',
        'Sucursales',
        'Empleados',
        'Roles',
      ]);
    });
  });

  group('isRouteActive', () {
    test('coincide con la ruta exacta', () {
      expect(isRouteActive('/sales', '/sales'), isTrue);
    });

    test('por defecto también coincide con subrutas', () {
      expect(isRouteActive('/sales/123', '/sales'), isTrue);
    });

    test('no confunde rutas con el mismo prefijo', () {
      expect(isRouteActive('/sales-history', '/sales'), isFalse);
    });

    test('con exact solo coincide con la ruta exacta', () {
      expect(
        isRouteActive('/products/categories', '/products', exact: true),
        isFalse,
      );
      expect(isRouteActive('/products', '/products', exact: true), isTrue);
    });
  });

  group('navigationTitleFor', () {
    test('devuelve la etiqueta del módulo', () {
      expect(navigationTitleFor('/home'), 'Inicio');
      expect(navigationTitleFor('/sales'), 'Ventas realizadas');
    });

    test('una subruta usa el módulo más específico', () {
      expect(navigationTitleFor('/products'), 'Lista de productos');
      expect(
        navigationTitleFor('/products/categories'),
        'Categorías de productos',
      );
      expect(navigationTitleFor('/sales/123'), 'Ventas realizadas');
    });

    test('la lista de preferencias y las rutas desconocidas', () {
      expect(navigationTitleFor('/preferences'), 'Preferencias');
      expect(navigationTitleFor('/desconocida'), 'Casca');
    });
  });
}
