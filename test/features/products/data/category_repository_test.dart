import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/features/products/data/category_endpoints.dart';
import 'package:casca_app/features/products/data/category_repository.dart';
import 'package:casca_app/features/products/data/models/category_request.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/network/fake_http_adapter.dart';

const _pageJson = {
  'items': [
    {
      'id': 'c1',
      'name': 'Abarrotes',
      'description': null,
      'parentCategoryId': null,
      'parentCategoryName': null,
    },
    {
      'id': 'c2',
      'name': 'Enlatados',
      'description': 'Latas',
      'parentCategoryId': 'c1',
      'parentCategoryName': 'Abarrotes',
    },
  ],
  'page': 1,
  'pageSize': 10,
  'totalCount': 2,
  'totalPages': 1,
  'hasNextPage': false,
  'hasPreviousPage': false,
};

CategoryRepository _repository(FakeHandler handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeHttpAdapter(handler);
  return CategoryRepository(ApiClient(dio, DefaultCookieJar()));
}

void main() {
  test('getCategories pide la página y devuelve las categorías', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': _pageJson}, 200);
    });

    final page = await repository.getCategories(
      search: 'lat',
      page: 2,
      pageSize: 20,
    );

    expect(sent?.path, CategoryEndpoints.list);
    expect(sent?.queryParameters, {
      'searchTerm': 'lat',
      'page': 2,
      'pageSize': 20,
      'sort': 'name',
      'order': 'asc',
    });
    expect(page.items.map((c) => c.name), ['Abarrotes', 'Enlatados']);
    expect(page.items.last.parentCategoryName, 'Abarrotes');
    expect(page.totalCount, 2);
  });

  test('getCategories pide el orden descendente por nombre', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': _pageJson}, 200);
    });

    await repository.getCategories(descending: true);

    expect(sent?.queryParameters['sort'], 'name');
    expect(sent?.queryParameters['order'], 'desc');
  });

  test(
    'getCategories no envía searchTerm cuando la búsqueda está vacía',
    () async {
      RequestOptions? sent;
      final repository = _repository((options) async {
        sent = options;
        return jsonResponse({'data': _pageJson}, 200);
      });

      await repository.getCategories();

      expect(sent?.queryParameters.containsKey('searchTerm'), isFalse);
      expect(sent?.queryParameters['page'], 1);
      expect(sent?.queryParameters['pageSize'], 10);
    },
  );

  test('getCategories propaga el error del servidor', () async {
    final repository = _repository(
      (_) async => jsonResponse({'message': 'Sin permiso'}, 403),
    );

    await expectLater(repository.getCategories(), throwsA(isA<ApiException>()));
  });

  test('createCategory envía los datos por POST', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': null}, 201);
    });

    await repository.createCategory(const CategoryRequest(name: 'Lácteos'));

    expect(sent?.method, 'POST');
    expect(sent?.path, CategoryEndpoints.list);
    expect(sent?.data, {
      'name': 'Lácteos',
      'description': null,
      'parentCategoryId': null,
    });
  });

  test('updateCategory envía los datos por PUT a la categoría', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': null}, 201);
    });

    await repository.updateCategory(
      'c2',
      const CategoryRequest(name: 'Conservas', parentCategoryId: 'c1'),
    );

    expect(sent?.method, 'PUT');
    expect(sent?.path, CategoryEndpoints.byId('c2'));
    expect((sent?.data as Map)['parentCategoryId'], 'c1');
  });

  test(
    'getCategories con rootOnly pide solo las categorías principales',
    () async {
      RequestOptions? sent;
      final repository = _repository((options) async {
        sent = options;
        return jsonResponse({'data': _pageJson}, 200);
      });

      await repository.getCategories(rootOnly: true);

      expect(sent?.queryParameters['rootOnly'], isTrue);
    },
  );

  test('deleteCategory usa DELETE sobre la categoría', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': null}, 200);
    });

    await repository.deleteCategory('c2');

    expect(sent?.method, 'DELETE');
    expect(sent?.path, CategoryEndpoints.byId('c2'));
  });
}
