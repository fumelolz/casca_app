import 'package:casca_app/core/layout/navigation_item.dart';
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

    test('con todos los permisos muestra los módulos al mismo nivel', () {
      final nav = buildNavigation(fullAccessSession());

      expect(nav.sections.map((s) => s.label), ['']);
      expect(_labels(nav), [
        'Inicio',
        'Vender',
        'Ventas realizadas',
        'Clientes',
        'Turno actual',
        'Historial de turnos',
        'Productos',
      ]);
      expect(
        nav.sections.single.items.where((item) => item.hasChildren),
        isEmpty,
      );
    });

    test('oculta los módulos para los que no hay permiso', () {
      final nav = buildNavigation(
        fullAccessSession(permissions: ['sale.view', 'product.view']),
      );

      expect(_labels(nav), ['Ventas realizadas', 'Productos']);
    });

    test('sin permisos de módulos no muestra ninguno', () {
      final nav = buildNavigation(fullAccessSession(permissions: ['x']));

      expect(_labels(nav), isEmpty);
    });

    test('anyPermission basta con tener uno de los permisos', () {
      final nav = buildNavigation(
        fullAccessSession(permissions: ['cashregister.operate']),
      );

      expect(_labels(nav), ['Turno actual']);
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
}
