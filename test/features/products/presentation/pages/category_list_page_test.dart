import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_repository.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/products/data/category_repository.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/data/models/category_request.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/features/products/presentation/pages/category_list_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/fake_auth_repository.dart';

class _FakeCategoryRepository implements CategoryRepository {
  final searches = <String>[];
  final pages = <int>[];
  final descendings = <bool>[];
  final rootOnlyRequests = <int>[];
  Object? error;
  Object? saveError;
  final created = <CategoryRequest>[];
  final updated = <String, CategoryRequest>{};
  final deleted = <String>[];
  Object? deleteError;

  @override
  Future<void> deleteCategory(String categoryId) async {
    final failure = deleteError;
    if (failure != null) throw failure;
    deleted.add(categoryId);
  }

  @override
  Future<void> createCategory(CategoryRequest request) async {
    final failure = saveError;
    if (failure != null) throw failure;
    created.add(request);
  }

  @override
  Future<void> updateCategory(
    String categoryId,
    CategoryRequest request,
  ) async {
    final failure = saveError;
    if (failure != null) throw failure;
    updated[categoryId] = request;
  }

  List<CategoryModel> items = const [
    CategoryModel(
      id: 'c1',
      name: 'Abarrotes',
      description: 'Productos de uso diario',
    ),
    CategoryModel(
      id: 'c2',
      name: 'Enlatados',
      parentCategoryId: 'c1',
      parentCategoryName: 'Abarrotes',
    ),
  ];

  @override
  Future<PagedResponse<CategoryModel>> getCategories({
    String search = '',
    int page = 1,
    int pageSize = 10,
    bool descending = false,
    bool rootOnly = false,
  }) async {
    searches.add(search);
    pages.add(page);
    descendings.add(descending);
    if (rootOnly) rootOnlyRequests.add(pageSize);
    final failure = error;
    if (failure != null) throw failure;
    return PagedResponse<CategoryModel>(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: items.isEmpty ? 0 : 25,
      totalPages: 3,
      hasNextPage: page < 3,
      hasPreviousPage: page > 1,
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeCategoryRepository repository, {
  double width = 900,
  List<String> permissions = const [
    'category.view',
    'category.create',
    'category.update',
    'category.delete',
  ],
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            hasSession: true,
            session: fullAccessSession(permissions: permissions),
          ),
        ),
      ],
      child: MaterialApp(
        theme: CascaTheme.light,
        home: const Scaffold(body: CategoryListPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra las categorías con su descripción y su padre', (
    tester,
  ) async {
    await _pump(tester, _FakeCategoryRepository());

    expect(find.text('Categorías de productos'), findsOneWidget);
    expect(find.text('Abarrotes'), findsNWidgets(2));
    expect(find.text('Productos de uso diario'), findsOneWidget);
    expect(find.text('Enlatados'), findsOneWidget);
    expect(find.text('1–10 de 25'), findsOneWidget);
  });

  testWidgets('en pantalla angosta oculta la descripción', (tester) async {
    await _pump(tester, _FakeCategoryRepository(), width: 400);

    expect(find.text('Enlatados'), findsOneWidget);
    expect(find.text('Productos de uso diario'), findsNothing);
    expect(find.text('Descripción'), findsNothing);
  });

  testWidgets('buscar espera la pausa y pide con el texto', (tester) async {
    final repository = _FakeCategoryRepository();
    await _pump(tester, repository);

    await tester.enterText(find.byType(TextField), 'lat');
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.searches, ['']);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(repository.searches.last, 'lat');
    expect(repository.pages.last, 1);
  });

  testWidgets('tocar Nombre alterna entre descendente y ascendente', (
    tester,
  ) async {
    final repository = _FakeCategoryRepository();
    await _pump(tester, repository);
    expect(repository.descendings.last, isFalse);

    await tester.tap(find.text('Nombre'));
    await tester.pumpAndSettle();
    expect(repository.descendings.last, isTrue);

    await tester.tap(find.text('Nombre'));
    await tester.pumpAndSettle();
    expect(repository.descendings.last, isFalse);
  });

  testWidgets('el botón siguiente pide la página 2', (tester) async {
    final repository = _FakeCategoryRepository();
    await _pump(tester, repository);

    await tester.tap(find.bySemanticsLabel('Página siguiente'));
    await tester.pumpAndSettle();

    expect(repository.pages.last, 2);
    expect(find.text('11–20 de 25'), findsOneWidget);
  });

  testWidgets('sin categorías muestra el mensaje de vacío', (tester) async {
    final repository = _FakeCategoryRepository()..items = const [];
    await _pump(tester, repository);

    expect(find.text('Aún no hay categorías.'), findsOneWidget);
  });

  testWidgets('con error muestra el mensaje y reintenta', (tester) async {
    final repository = _FakeCategoryRepository()
      ..error = const ApiException(type: ApiErrorType.network);
    await _pump(tester, repository);

    expect(find.text('No fue posible obtener las categorías.'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Enlatados'), findsOneWidget);
    expect(repository.pages, hasLength(2));
  });

  group('permisos', () {
    testWidgets('sin permisos no muestra agregar ni acciones', (tester) async {
      await _pump(
        tester,
        _FakeCategoryRepository(),
        permissions: const ['category.view'],
      );

      expect(find.text('Agregar categoría'), findsNothing);
      expect(find.text('Acciones'), findsNothing);
      expect(find.byType(CascaActionMenu), findsNothing);
    });

    testWidgets('con permisos muestra agregar y la columna de acciones', (
      tester,
    ) async {
      await _pump(tester, _FakeCategoryRepository());

      expect(find.text('Agregar categoría'), findsOneWidget);
      expect(find.text('Acciones'), findsOneWidget);
      expect(find.byType(CascaActionMenu), findsNWidgets(2));
    });
  });

  group('formulario', () {
    Future<void> openEdit(WidgetTester tester) async {
      await tester.tap(find.byType(CascaActionMenu).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
    }

    testWidgets('editar precarga la categoría y guarda los cambios', (
      tester,
    ) async {
      final repository = _FakeCategoryRepository();
      await _pump(tester, repository);

      await openEdit(tester);
      expect(find.text('Editar categoría'), findsOneWidget);
      final nameField = find.widgetWithText(TextField, 'Enlatados');
      expect(nameField, findsOneWidget);

      await tester.enterText(nameField, 'Conservas');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(repository.updated['c2']?.name, 'Conservas');
      expect(repository.updated['c2']?.parentCategoryId, 'c1');
      expect(repository.updated['c2']?.description, isNull);
      expect(find.text('Editar categoría'), findsNothing);
      expect(repository.pages.length, greaterThan(2));
    });

    testWidgets('el selector de padre pide solo categorías principales', (
      tester,
    ) async {
      final repository = _FakeCategoryRepository();
      await _pump(tester, repository);
      expect(repository.rootOnlyRequests, isEmpty);

      await tester.tap(find.text('Agregar categoría'));
      await tester.pumpAndSettle();

      expect(repository.rootOnlyRequests, [100]);
    });

    testWidgets('agregar exige el nombre', (tester) async {
      final repository = _FakeCategoryRepository();
      await _pump(tester, repository);

      await tester.tap(find.text('Agregar categoría'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa el nombre'), findsOneWidget);
      expect(repository.created, isEmpty);
    });

    testWidgets('agregar envía la categoría sin padre', (tester) async {
      final repository = _FakeCategoryRepository();
      await _pump(tester, repository);

      await tester.tap(find.text('Agregar categoría'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '  Lácteos ');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(repository.created.single.name, 'Lácteos');
      expect(repository.created.single.parentCategoryId, isNull);
      expect(find.text('Guardar'), findsNothing);
    });

    testWidgets('si guardar falla muestra el error y sigue abierto', (
      tester,
    ) async {
      final repository = _FakeCategoryRepository()
        ..saveError = const ApiException(
          type: ApiErrorType.client,
          statusCode: 409,
          serverMessage: 'Ya existe una categoría con ese nombre.',
        );
      await _pump(tester, repository);

      await openEdit(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ya existe una categoría con ese nombre.'),
        findsOneWidget,
      );
      expect(find.text('Editar categoría'), findsOneWidget);
    });
  });

  group('eliminar', () {
    Future<void> openDelete(WidgetTester tester) async {
      await tester.tap(find.byType(CascaActionMenu).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
    }

    testWidgets('pide confirmación y no borra si se cancela', (tester) async {
      final repository = _FakeCategoryRepository();
      await _pump(tester, repository);

      await openDelete(tester);
      expect(find.text('¿Eliminar Enlatados?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repository.deleted, isEmpty);
      expect(find.text('¿Eliminar Enlatados?'), findsNothing);
    });

    testWidgets('al confirmar borra, cierra y recarga la lista', (
      tester,
    ) async {
      final repository = _FakeCategoryRepository();
      await _pump(tester, repository);
      final requests = repository.pages.length;

      await openDelete(tester);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(repository.deleted, ['c2']);
      expect(find.text('¿Eliminar Enlatados?'), findsNothing);
      expect(repository.pages.length, greaterThan(requests));
    });

    testWidgets('si el backend lo rechaza muestra su mensaje', (tester) async {
      final repository = _FakeCategoryRepository()
        ..deleteError = const ApiException(
          type: ApiErrorType.client,
          statusCode: 409,
          serverMessage: 'Tiene productos asociados.',
        );
      await _pump(tester, repository);

      await openDelete(tester);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Tiene productos asociados.'), findsOneWidget);
      expect(find.text('¿Eliminar Enlatados?'), findsOneWidget);
    });

    testWidgets('sin permiso no ofrece eliminar', (tester) async {
      await _pump(
        tester,
        _FakeCategoryRepository(),
        permissions: const ['category.view', 'category.update'],
      );

      await tester.tap(find.byType(CascaActionMenu).first);
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsNothing);
    });
  });
}
