import 'package:casca_app/core/network/paged_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('construye la página con sus elementos y datos de control', () {
    final page = PagedResponse<String>.fromJson({
      'items': [
        {'name': 'Abarrotes'},
        {'name': 'Bebidas'},
      ],
      'page': 1,
      'pageSize': 2,
      'totalCount': 5,
      'totalPages': 3,
      'hasNextPage': true,
      'hasPreviousPage': false,
    }, (item) => item['name'] as String);

    expect(page.items, ['Abarrotes', 'Bebidas']);
    expect(page.page, 1);
    expect(page.pageSize, 2);
    expect(page.totalCount, 5);
    expect(page.totalPages, 3);
    expect(page.hasNextPage, isTrue);
    expect(page.hasPreviousPage, isFalse);
  });
}
