import 'dart:ui';

import 'package:casca_app/features/customers/presentation/pages/customer_list_page.dart';
import 'package:casca_app/core/customers/customer_model.dart';
import 'package:casca_app/core/customers/customer_repository.dart';
import 'package:casca_app/features/home/data/dashboard_repository.dart';
import 'package:casca_app/features/home/data/models/dashboard_summary_model.dart';
import 'package:casca_app/features/home/domain/dashboard_rules.dart';
import 'package:casca_app/app/router/app_router.dart';
import 'package:casca_app/app/theme/casca_colors.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/layout/brand_lockup.dart';
import 'package:casca_app/core/layout/mobile_bottom_bar.dart';
import 'package:casca_app/core/layout/preferences_nav.dart';
import 'package:casca_app/core/layout/sidebar.dart';
import 'package:casca_app/core/layout/topbar.dart';
import 'package:casca_app/core/layout/topbar_icon_button.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/cash_registers/data/current_shift_repository.dart';
import 'package:casca_app/features/cash_registers/data/models/current_shift_model.dart';
import 'package:casca_app/features/cash_registers/data/models/shift_model.dart';
import 'package:casca_app/features/cash_registers/data/shift_repository.dart';
import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/data/pos_repository.dart';
import 'package:casca_app/features/pos/presentation/pages/pos_page.dart';
import 'package:casca_app/features/sales/data/models/sale_history_model.dart';
import 'package:casca_app/features/sales/data/sales_repository.dart';
import 'package:casca_app/features/sales/presentation/pages/sales_history_page.dart';
import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/features/products/data/product_repository.dart';
import 'package:casca_app/features/products/presentation/pages/product_list_page.dart';
import 'package:casca_app/shared/ui/casca_tooltip.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_auth_repository.dart';

class _EmptySalesRepository implements SalesRepository {
  @override
  Future<PagedResponse<SaleListItemModel>> getSales({
    required int page,
    required int pageSize,
    String search = '',
    SaleSortField sort = SaleSortField.created,
    bool descending = true,
  }) async {
    return const PagedResponse(
      items: [],
      page: 1,
      pageSize: 10,
      totalCount: 0,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCurrentShiftRepository implements CurrentShiftRepository {
  @override
  Future<CurrentShiftModel?> getCurrent() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyShiftRepository implements ShiftRepository {
  @override
  Future<PagedResponse<ShiftListItemModel>> getShifts({
    required int page,
    required int pageSize,
  }) async {
    return const PagedResponse(
      items: [],
      page: 1,
      pageSize: 10,
      totalCount: 0,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyPosRepository implements PosRepository {
  @override
  Future<PosCatalogPageModel> catalog(
    String search,
    int page, {
    String? priceListId,
  }) async {
    return const PosCatalogPageModel(items: [], hasNextPage: false);
  }

  @override
  Future<bool> hasActiveShift() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyCustomerRepository implements CustomerRepository {
  @override
  Future<PagedResponse<CustomerModel>> getCustomers({
    required int page,
    required int pageSize,
    String search = '',
    String? status,
  }) async {
    return const PagedResponse(
      items: [],
      page: 1,
      pageSize: 10,
      totalCount: 0,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _EmptyDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummaryModel> getSummary() async {
    return const DashboardSummaryModel(
      todayTotal: 0,
      todayOrders: 0,
      averageTicket: 0,
      yesterdayTotal: 0,
      percentageChange: 0,
      todayProfit: 0,
    );
  }

  @override
  Future<List<DashboardWidgetSetting>> getLayout() async => const [];
}

class _EmptyProductRepository implements ProductRepository {
  @override
  Future<PagedResponse<ProductListItemModel>> getProducts({
    String search = '',
    int page = 1,
    int pageSize = 10,
    ProductSortField sort = ProductSortField.created,
    bool descending = true,
  }) async {
    return const PagedResponse(
      items: [],
      page: 1,
      pageSize: 10,
      totalCount: 0,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _desktop = Size(1100, 800);
const _phone = Size(400, 800);

Future<void> _openApp(
  WidgetTester tester, {
  Size size = _desktop,
  SessionState? session,
  FakeViewPadding padding = FakeViewPadding.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.view.padding = padding;
  tester.view.viewPadding = padding;

  final repo = FakeAuthRepository(
    hasSession: true,
    session: session ?? fullAccessSession(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        productRepositoryProvider.overrideWithValue(_EmptyProductRepository()),
        posRepositoryProvider.overrideWithValue(_EmptyPosRepository()),
        shiftRepositoryProvider.overrideWithValue(_EmptyShiftRepository()),
        customerRepositoryProvider.overrideWithValue(
          _EmptyCustomerRepository(),
        ),
        dashboardRepositoryProvider.overrideWithValue(
          _EmptyDashboardRepository(),
        ),
        currentShiftRepositoryProvider.overrideWithValue(
          _NoCurrentShiftRepository(),
        ),
        salesRepositoryProvider.overrideWithValue(_EmptySalesRepository()),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: CascaTheme.light,
          routerConfig: ref.watch(routerProvider),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _inSidebar(String text) {
  return find.descendant(of: find.byType(Sidebar), matching: find.text(text));
}

Finder _inBackBar() {
  return find.descendant(
    of: find.byType(PreferencesNav),
    matching: find.text('Preferencias'),
  );
}

final _activeBackground = CascaColors.light.text.withValues(alpha: 0.1);
Color? _tileColor(WidgetTester tester, String label) {
  final tile = find
      .ancestor(of: _inSidebar(label), matching: find.byType(AnimatedContainer))
      .first;
  final decoration = tester.widget<AnimatedContainer>(tile).decoration;
  return (decoration as BoxDecoration?)?.color;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _inBar(String text) {
  return find.descendant(
    of: find.byType(MobileBottomBar),
    matching: find.text(text),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  await _tap(tester, find.byType(TopbarIconButton).first);
}

bool _isDrawerOpen(WidgetTester tester) {
  return tester.getTopLeft(_inSidebar('Vender')).dx >= 0;
}

double _maxScale(WidgetTester tester) {
  final scales = tester.widgetList<ScaleTransition>(
    find.descendant(
      of: find.byType(MobileBottomBar),
      matching: find.byType(ScaleTransition),
    ),
  );
  return scales.map((s) => s.scale.value).reduce((a, b) => a > b ? a : b);
}

bool _isTabActive(WidgetTester tester, String label) {
  final text = tester.widget<Text>(_inBar(label));
  return text.style?.color == CascaColors.light.text;
}

Future<void> _collapse(WidgetTester tester) async {
  await _tap(tester, find.byType(TopbarIconButton).first);
}

void main() {
  group('escritorio', () {
    testWidgets('muestra los módulos permitidos sin secciones', (
      tester,
    ) async {
      await _openApp(tester);

      expect(find.text('PRINCIPAL'), findsNothing);
      expect(find.text('OPERACIÓN'), findsNothing);
      expect(_inSidebar('Ventas realizadas'), findsOneWidget);
      expect(_inSidebar('Turno actual'), findsOneWidget);
      expect(_inSidebar('Resumen de reportes'), findsNothing);
      expect(_inSidebar('Preferencias'), findsOneWidget);
      expect(find.byType(Sidebar), findsOneWidget);
    });

    testWidgets('oculta los módulos sin permiso', (tester) async {
      await _openApp(
        tester,
        session: fullAccessSession(permissions: ['sale.view']),
      );

      expect(_inSidebar('Ventas realizadas'), findsOneWidget);
      expect(_inSidebar('Vender'), findsNothing);
      expect(_inSidebar('Productos'), findsNothing);
    });

    testWidgets('al tocar un módulo navega y lo marca como activo', (
      tester,
    ) async {
      await _openApp(tester);

      await _tap(tester, _inSidebar('Clientes'));

      expect(find.text('Clientes'), findsNWidgets(2));
      expect(_tileColor(tester, 'Clientes'), _activeBackground);
      expect(_tileColor(tester, 'Vender'), isNull);
    });

    testWidgets('Productos abre la lista sin desplegar un submenú', (
      tester,
    ) async {
      await _openApp(tester);
      expect(_inSidebar('Categorías de productos'), findsNothing);

      await _tap(tester, _inSidebar('Productos'));

      expect(find.byType(ProductListPage), findsOneWidget);
      expect(_tileColor(tester, 'Productos'), _activeBackground);
    });

    testWidgets('el historial de turnos está al primer nivel', (tester) async {
      await _openApp(tester);

      await _tap(tester, _inSidebar('Historial de turnos'));

      expect(find.text('Historial de turnos'), findsNWidgets(2));
      expect(_tileColor(tester, 'Historial de turnos'), _activeBackground);
    });

    testWidgets('el botón contrae el menú a solo iconos', (tester) async {
      await _openApp(tester);
      expect(
        find.descendant(
          of: find.byType(Sidebar),
          matching: find.byType(IconButton),
        ),
        findsNothing,
      );
      expect(find.byType(TopbarIconButton), findsNWidgets(2));

      await _collapse(tester);

      expect(_inSidebar('Vender'), findsNothing);
      expect(find.text('Casca'), findsNothing);
      expect(find.byType(TopbarIconButton), findsNWidgets(2));

      await _tap(tester, find.byType(TopbarIconButton).first);

      expect(_inSidebar('Vender'), findsOneWidget);
    });

    testWidgets('el menú y la campana son botones grandes', (tester) async {
      await _openApp(tester);

      for (final button in find.byType(TopbarIconButton).evaluate()) {
        final size = tester.getSize(find.byWidget(button.widget));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('el botón del menú explica su acción al pasar el cursor', (
      tester,
    ) async {
      await _openApp(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(tester.getCenter(find.byType(TopbarIconButton).first));
      await tester.pump();
      expect(find.text('Contraer menú'), findsOneWidget);

      await tester.tap(find.byType(TopbarIconButton).first);
      await tester.pumpAndSettle();
      await mouse.moveTo(const Offset(700, 400));
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byType(TopbarIconButton).first));
      await tester.pump();

      expect(find.text('Expandir menú'), findsOneWidget);
    });
    testWidgets('contraído muestra el nombre al pasar el cursor', (
      tester,
    ) async {
      await _openApp(tester);
      await _collapse(tester);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(CascaTooltip).at(1)));
      await tester.pump();

      expect(find.text('Vender'), findsOneWidget);

      await mouse.moveTo(const Offset(700, 400));
      await tester.pump();

      expect(find.text('Vender'), findsNothing);
    });

    testWidgets('contraído, el turno actual navega sin flyout', (
      tester,
    ) async {
      await _openApp(tester);
      await _collapse(tester);

      await _tap(tester, find.byType(CascaTooltip).at(4));

      expect(find.text('No hay un turno activo'), findsOneWidget);
    });

    testWidgets('la barra superior muestra la tienda y el nombre', (
      tester,
    ) async {
      await _openApp(tester);

      expect(find.text('Casa Magadan'), findsOneWidget);
      expect(find.text('Daniel Magadan'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('el menú de cuenta ofrece cerrar sesión', (tester) async {
      await _openApp(tester);

      await _tap(tester, find.text('Casa Magadan'));

      expect(find.text('MI CUENTA'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('las notificaciones están vacías y llevan a los negocios', (
      tester,
    ) async {
      await _openApp(tester);

      await _tap(tester, find.byType(TopbarIconButton).last);
      expect(find.text('No tienes notificaciones.'), findsOneWidget);

      await _tap(tester, find.text('Ver mis negocios'));

      expect(find.text('No tienes notificaciones.'), findsNothing);
      expect(find.text('Negocios'), findsWidgets);
    });
  });

  group('preferencias', () {
    testWidgets('el panel lateral solo aparece en preferencias', (
      tester,
    ) async {
      await _openApp(tester);
      expect(find.text('PREFERENCIAS'), findsNothing);

      await _tap(tester, _inSidebar('Preferencias'));

      expect(find.text('PREFERENCIAS'), findsOneWidget);
      expect(find.text('Organización'), findsOneWidget);
      expect(find.text('Catálogo en línea'), findsWidgets);
    });

    testWidgets('navegar dentro de preferencias marca el enlace activo', (
      tester,
    ) async {
      await _openApp(tester);
      await _tap(tester, _inSidebar('Preferencias'));

      await _tap(tester, find.text('Apariencia'));

      expect(find.text('Apariencia'), findsNWidgets(2));
      expect(_tileColor(tester, 'Preferencias'), _activeBackground);
    });
  });

  group('móvil', () {
    Finder inTopbar(String text) {
      return find.descendant(
        of: find.byType(Topbar),
        matching: find.text(text),
      );
    }

    group('menú lateral', () {
      testWidgets('está oculto y se abre con el botón de la barra', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);
        expect(_isDrawerOpen(tester), isFalse);
        expect(find.text('Casca'), findsOneWidget);
        expect(find.text('Casa Magadan'), findsNothing);

        await _openDrawer(tester);

        expect(_isDrawerOpen(tester), isTrue);
      });

      testWidgets('el botón es grande y la barra no tiene otro botón de menú', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);

        final size = tester.getSize(find.byType(TopbarIconButton).first);

        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      });

      testWidgets('al elegir un módulo navega y se cierra el menú', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);
        await _openDrawer(tester);

        await _tap(tester, _inSidebar('Clientes'));

        expect(find.byType(CustomerListPage), findsOneWidget);
        expect(_isDrawerOpen(tester), isFalse);
      });

      testWidgets('tapar el fondo oscuro cierra el menú', (tester) async {
        await _openApp(tester, size: _phone);
        await _openDrawer(tester);

        await tester.tapAt(const Offset(380, 500));
        await tester.pumpAndSettle();

        expect(_isDrawerOpen(tester), isFalse);
      });

      testWidgets('Escape cierra el menú', (tester) async {
        await _openApp(tester, size: _phone);
        await _openDrawer(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(_isDrawerOpen(tester), isFalse);
      });

      testWidgets('deslizar desde el borde izquierdo abre el menú', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);

        await tester.dragFrom(const Offset(4, 400), const Offset(200, 0));
        await tester.pumpAndSettle();

        expect(_isDrawerOpen(tester), isTrue);
      });

      testWidgets('deslizar desde otro punto no abre el menú', (tester) async {
        await _openApp(tester, size: _phone);

        await tester.dragFrom(const Offset(200, 400), const Offset(150, 0));
        await tester.pumpAndSettle();

        expect(_isDrawerOpen(tester), isFalse);
      });

      testWidgets('deslizar el menú hacia la izquierda lo cierra', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);
        await _openDrawer(tester);

        await tester.fling(find.byType(Sidebar), const Offset(-200, 0), 1000);
        await tester.pumpAndSettle();

        expect(_isDrawerOpen(tester), isFalse);
      });

      testWidgets('el menú abierto cubre la barra inferior', (tester) async {
        await _openApp(tester, size: _phone);
        await _openDrawer(tester);

        expect(tester.getBottomLeft(find.byType(Sidebar)).dy, 800);
      });
    });

    group('barra inferior', () {
      testWidgets('muestra los cinco accesos con Vender en el centro', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);

        final labels = ['Inicio', 'Ventas', 'Vender', 'Caja', 'Productos'];
        final xs = [
          for (final label in labels) tester.getCenter(_inBar(label)).dx,
        ];

        expect(xs, orderedEquals([...xs]..sort()));
        expect(xs[2], closeTo(200, 1));
      });

      testWidgets('con menos permisos Vender sigue en el medio', (
        tester,
      ) async {
        await _openApp(
          tester,
          size: _phone,
          session: fullAccessSession(
            permissions: [
              'dashboard.view',
              'sale.create',
              'cashregister.open',
              'product.view',
            ],
          ),
        );

        final labels = ['Inicio', 'Caja', 'Vender', 'Productos'];
        final xs = [
          for (final label in labels) tester.getCenter(_inBar(label)).dx,
        ];

        expect(xs, orderedEquals([...xs]..sort()));
        expect(_inBar('Ventas'), findsNothing);
      });

      testWidgets('solo muestra los accesos con permiso', (tester) async {
        await _openApp(
          tester,
          size: _phone,
          session: fullAccessSession(permissions: ['sale.create']),
        );

        expect(_inBar('Vender'), findsOneWidget);
        expect(_inBar('Inicio'), findsNothing);
        expect(_inBar('Productos'), findsNothing);
      });

      testWidgets('sin permiso de vender no hay resaltado', (tester) async {
        await _openApp(
          tester,
          size: _phone,
          session: fullAccessSession(
            permissions: ['dashboard.view', 'product.view'],
          ),
        );

        expect(_inBar('Vender'), findsNothing);
        expect(tester.getSize(find.byType(MobileBottomBar)).height, 64 + 1);
      });

      testWidgets('el acceso activo solo cambia de color, sin píldora', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);
        expect(_isTabActive(tester, 'Inicio'), isTrue);
        expect(_isTabActive(tester, 'Caja'), isFalse);
        expect(
          find.descendant(
            of: find.byType(MobileBottomBar),
            matching: find.byType(AnimatedContainer),
          ),
          findsNothing,
        );

        await _tap(tester, _inBar('Caja'));

        expect(_isTabActive(tester, 'Caja'), isTrue);
        expect(_isTabActive(tester, 'Inicio'), isFalse);
      });

      testWidgets('al activarse un acceso hace un pequeño rebote', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);
        expect(_maxScale(tester), 1);

        await tester.tap(_inBar('Ventas'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        expect(_maxScale(tester), greaterThan(1));

        await tester.pumpAndSettle();

        expect(_maxScale(tester), 1);
      });

      testWidgets('el color pasa de gris a oscuro de forma gradual', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);
        final grey = CascaColors.light.textSecondary;
        final target = CascaColors.light.text;

        await tester.tap(_inBar('Caja'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final midway = tester.widget<Text>(_inBar('Caja')).style?.color;
        expect(midway, isNot(grey));
        expect(midway, isNot(target));

        await tester.pumpAndSettle();

        expect(tester.widget<Text>(_inBar('Caja')).style?.color, target);
      });

      testWidgets('con animaciones reducidas no hay rebote ni degradado', (
        tester,
      ) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await _openApp(tester, size: _phone);

        await tester.tap(_inBar('Ventas'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        expect(_maxScale(tester), 1);
        expect(
          tester.widget<Text>(_inBar('Ventas')).style?.color,
          CascaColors.light.text,
        );
      });

      testWidgets('la etiqueta activa va en negrita', (tester) async {
        await _openApp(tester, size: _phone);

        FontWeight? weight(String label) =>
            tester.widget<Text>(_inBar(label)).style?.fontWeight;

        expect(weight('Inicio'), FontWeight.w600);
        expect(weight('Caja'), FontWeight.w500);

        await _tap(tester, _inBar('Caja'));

        expect(weight('Caja'), FontWeight.w600);
        expect(weight('Inicio'), FontWeight.w500);
      });
      testWidgets('al tocar un acceso navega a su pantalla', (tester) async {
        await _openApp(tester, size: _phone);

        await _tap(tester, _inBar('Ventas'));

        expect(find.byType(SalesHistoryPage), findsOneWidget);
      });

      testWidgets('Vender se ve como los demás accesos', (tester) async {
        await _openApp(tester, size: _phone);
        Color? color(String label) =>
            tester.widget<Text>(_inBar(label)).style?.color;

        expect(color('Vender'), color('Caja'));

        await _tap(tester, _inBar('Vender'));

        expect(find.byType(PosPage), findsOneWidget);
        expect(_isTabActive(tester, 'Vender'), isTrue);
      });

      testWidgets('Productos queda activo al entrar desde el menú', (
        tester,
      ) async {
        await _openApp(tester, size: _phone);
        await _openDrawer(tester);
        await _tap(tester, _inSidebar('Productos'));

        expect(_isTabActive(tester, 'Productos'), isTrue);
      });

      testWidgets('en escritorio no hay barra inferior', (tester) async {
        await _openApp(tester);

        expect(find.byType(MobileBottomBar), findsNothing);
      });
    });

    testWidgets('la barra superior muestra el logo y Casca Tiendas', (
      tester,
    ) async {
      await _openApp(tester, size: _phone);

      expect(inTopbar('Casca'), findsOneWidget);
      expect(inTopbar('Tiendas'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Topbar),
          matching: find.byType(BrandMark),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la marca se queda igual al cambiar de pantalla', (
      tester,
    ) async {
      await _openApp(tester, size: _phone);

      await _tap(tester, _inBar('Productos'));

      expect(inTopbar('Casca'), findsOneWidget);
      expect(find.byType(ProductListPage), findsOneWidget);
    });

    testWidgets('en una pantalla angosta la marca no se desborda', (
      tester,
    ) async {
      await _openApp(tester, size: const Size(320, 640));

      expect(tester.takeException(), isNull);
      expect(inTopbar('Casca'), findsOneWidget);
      expect(inTopbar('Tiendas'), findsNothing);
    });

    testWidgets('en escritorio la marca solo está en el menú lateral', (
      tester,
    ) async {
      await _openApp(tester);

      expect(
        find.descendant(
          of: find.byType(Topbar),
          matching: find.byType(BrandLockup),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(Sidebar),
          matching: find.byType(BrandLockup),
        ),
        findsOneWidget,
      );
    });

    group('márgenes del sistema', () {
      const status = 40.0;
      const navigation = 30.0;
      const padding = FakeViewPadding(top: status, bottom: navigation);

      testWidgets('la barra superior queda debajo de la barra de estado', (
        tester,
      ) async {
        await _openApp(tester, size: _phone, padding: padding);

        expect(tester.getSize(find.byType(Topbar)).height, 64 + status);
        expect(
          tester.getTopLeft(find.byType(TopbarIconButton).first).dy,
          greaterThanOrEqualTo(status),
        );
      });

      testWidgets('la barra inferior respeta la barra de navegación', (
        tester,
      ) async {
        await _openApp(tester, size: _phone, padding: padding);

        final bar = tester.getRect(find.byType(MobileBottomBar));
        final page = tester.getRect(find.byKey(const Key('home-page')));

        expect(bar.bottom, 800);
        expect(bar.height, 64 + 1 + navigation);
        expect(
          tester.getBottomLeft(_inBar('Vender')).dy,
          lessThanOrEqualTo(800 - navigation),
        );
        expect(page.bottom, lessThanOrEqualTo(800 - (64 + 1 + navigation)));
      });

      testWidgets('el menú lateral respeta ambos márgenes', (tester) async {
        await _openApp(tester, size: _phone, padding: padding);
        await _openDrawer(tester);

        expect(tester.getTopLeft(find.byType(Sidebar)).dy, 64 + status);
        expect(
          tester.getBottomLeft(_inSidebar('Preferencias')).dy,
          lessThanOrEqualTo(800 - navigation),
        );
      });

      testWidgets('en escritorio no se agregan márgenes', (tester) async {
        await _openApp(tester);

        expect(tester.getSize(find.byType(Topbar)).height, 64);
      });
    });

    group('preferencias', () {
      Future<void> openHub(WidgetTester tester) async {
        await _openApp(tester, size: _phone);
        await _openDrawer(tester);
        await _tap(tester, _inSidebar('Preferencias'));
      }

      testWidgets('el pie del menú abre la lista con todas las opciones', (
        tester,
      ) async {
        await openHub(tester);

        expect(find.byKey(const Key('preferences-hub')), findsOneWidget);
        expect(find.text('GENERAL'), findsOneWidget);
        expect(find.text('ORGANIZACIÓN'), findsOneWidget);
        for (final label in [
          'Catálogo en línea',
          'Apariencia',
          'Negocios',
          'Sucursales',
          'Empleados',
          'Roles',
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
        expect(_isDrawerOpen(tester), isFalse);
      });

      testWidgets('la lista oculta las opciones sin permiso', (tester) async {
        await _openApp(
          tester,
          size: _phone,
          session: fullAccessSession(permissions: ['store.view']),
        );
        await _openDrawer(tester);
        await _tap(tester, _inSidebar('Preferencias'));

        expect(find.text('Sucursales'), findsOneWidget);
        expect(find.text('Roles'), findsNothing);
        expect(find.text('Empleados'), findsNothing);
      });

      testWidgets('una opción abre su pantalla con barra para volver', (
        tester,
      ) async {
        await openHub(tester);

        await _tap(tester, find.text('Apariencia'));

        expect(find.byKey(const Key('preferences-hub')), findsNothing);
        expect(find.text('Apariencia'), findsOneWidget);
        expect(_inBackBar(), findsOneWidget);
        expect(find.text('PREFERENCIAS'), findsNothing);
      });

      testWidgets('la barra devuelve a la lista', (tester) async {
        await openHub(tester);
        await _tap(tester, find.text('Apariencia'));

        await _tap(tester, _inBackBar());

        expect(find.byKey(const Key('preferences-hub')), findsOneWidget);
      });
    });
  });

  group('escritorio sin lista', () {
    testWidgets('el pie del menú abre la primera opción con panel lateral', (
      tester,
    ) async {
      await _openApp(tester);

      await _tap(tester, _inSidebar('Preferencias'));

      expect(find.byKey(const Key('preferences-hub')), findsNothing);
      expect(find.text('PREFERENCIAS'), findsOneWidget);
      expect(find.text('Volver a preferencias'), findsNothing);
    });
  });
}
