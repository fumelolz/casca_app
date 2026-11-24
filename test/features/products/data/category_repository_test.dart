import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/features/products/data/category_endpoints.dart';
import 'package:casca_app/features/products/data/category_repository.dart';
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
      'q': 'lat',
      'sort': 'name',
      'order': 'asc',
      'page': 2,
      'pageSize': 20,
    });
    expect(page.items.map((c) => c.name), ['Abarrotes', 'Enlatados']);
    expect(page.items.last.parentCategoryName, 'Abarrotes');
    expect(page.totalCount, 2);
  });

  test('getCategories no envía q cuando la búsqueda está vacía', () async {
    RequestOptions? sent;
    final repository = _repository((options) async {
      sent = options;
      return jsonResponse({'data': _pageJson}, 200);
    });

    await repository.getCategories();

    expect(sent?.queryParameters.containsKey('q'), isFalse);
    expect(sent?.queryParameters['page'], 1);
    expect(sent?.queryParameters['pageSize'], 10);
  });

  test('getCategories propaga el error del servidor', () async {
    final repository = _repository(
      (_) async => jsonResponse({'message': 'Sin permiso'}, 403),
    );

    await expectLater(repository.getCategories(), throwsA(isA<ApiException>()));
  });
}
