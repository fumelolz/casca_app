import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/products/data/category_repository.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/presentation/providers/category_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Call {
  const _Call(this.search, this.page, this.pageSize, this.descending);

  final String search;
  final int page;
  final int pageSize;
  final bool descending;
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final calls = <_Call>[];
  Object? error;

  @override
  Future<PagedResponse<CategoryModel>> getCategories({
    String search = '',
    int page = 1,
    int pageSize = 10,
    bool descending = false,
    bool rootOnly = false,
  }) async {
    calls.add(_Call(search, page, pageSize, descending));
    final failure = error;
    if (failure != null) throw failure;
    return PagedResponse<CategoryModel>(
      items: [CategoryModel(id: 'c$page', name: 'Categoría $page')],
      page: page,
      pageSize: pageSize,
      totalCount: 30,
      totalPages: 3,
      hasNextPage: page < 3,
      hasPreviousPage: page > 1,
    );
  }
}

ProviderContainer _container(_FakeCategoryRepository repository) {
  final container = ProviderContainer(
    overrides: [categoryRepositoryProvider.overrideWithValue(repository)],
  );
  container.listen(categoryListProvider, (_, _) {});
  addTearDown(container.dispose);
  return container;
}

Future<void> _waitSearchDelay() {
  return Future<void>.delayed(
    CategoryListQueryController.searchDelay + const Duration(milliseconds: 50),
  );
}

void main() {
  test('carga la primera página con los valores por defecto', () async {
    final repository = _FakeCategoryRepository();
    final container = _container(repository);

    final page = await container.read(categoryListProvider.future);

    expect(page.items.single.name, 'Categoría 1');
    expect(repository.calls.single.search, '');
    expect(repository.calls.single.page, 1);
    expect(repository.calls.single.pageSize, 10);
  });

  test('setPage vuelve a pedir la página indicada', () async {
    final repository = _FakeCategoryRepository();
    final container = _container(repository);
    await container.read(categoryListProvider.future);

    container.read(categoryListQueryProvider.notifier).setPage(2);
    final page = await container.read(categoryListProvider.future);

    expect(page.page, 2);
    expect(repository.calls.last.page, 2);
  });

  test(
    'setSearch espera la pausa, pide una sola vez y vuelve a la página 1',
    () async {
      final repository = _FakeCategoryRepository();
      final container = _container(repository);
      final query = container.read(categoryListQueryProvider.notifier);
      await container.read(categoryListProvider.future);
      query.setPage(3);
      await container.read(categoryListProvider.future);
      repository.calls.clear();

      query
        ..setSearch('l')
        ..setSearch('la')
        ..setSearch('lat');
      expect(repository.calls, isEmpty);

      await _waitSearchDelay();
      await container.read(categoryListProvider.future);

      expect(repository.calls, hasLength(1));
      expect(repository.calls.single.search, 'lat');
      expect(repository.calls.single.page, 1);
    },
  );

  test(
    'setDescending pide el orden descendente y vuelve a la página 1',
    () async {
      final repository = _FakeCategoryRepository();
      final container = _container(repository);
      final query = container.read(categoryListQueryProvider.notifier);
      await container.read(categoryListProvider.future);
      query.setPage(3);
      await container.read(categoryListProvider.future);

      query.setDescending(true);
      await container.read(categoryListProvider.future);

      expect(repository.calls.last.descending, isTrue);
      expect(repository.calls.last.page, 1);
    },
  );

  test(
    'un error del repositorio queda en el estado y se puede reintentar',
    () async {
      final repository = _FakeCategoryRepository()
        ..error = const ApiException(type: ApiErrorType.network);
      final container = _container(repository);

      await expectLater(
        container.read(categoryListProvider.future),
        throwsA(isA<ApiException>()),
      );
      expect(container.read(categoryListProvider).hasError, isTrue);

      repository.error = null;
      container.invalidate(categoryListProvider);
      final page = await container.read(categoryListProvider.future);

      expect(page.items, isNotEmpty);
    },
  );
}
