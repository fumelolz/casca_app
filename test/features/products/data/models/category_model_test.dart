import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('construye la categoria desde el json sin categoria padre', () {
    final category = CategoryModel.fromJson({
      'id': '01a20f37-a373-77f0-aa03-55d220067a32',
      'name': 'Abarrotes',
      'description': 'Categoria abarrotes engloba la mayoria de productos',
      'parentCategoryId': null,
      'parentCategoryName': null,
    });

    expect(category.id, '01a20f37-a373-77f0-aa03-55d220067a32');
    expect(category.name, 'Abarrotes');
    expect(
      category.description,
      'Categoria abarrotes engloba la mayoria de productos',
    );
    expect(category.parentCategoryId, isNull);
    expect(category.parentCategoryName, isNull);
  });

  test('construye la categoria desde el json con categoria padre', () {
    final category = CategoryModel.fromJson({
      'id': '01a20f3b-28b1-7be8-8350-974136ee38b0',
      'name': 'Enlatados',
      'description':
          'Categoria de articulos enlatados, como salsa de tomate etc.',
      'parentCategoryId': '01a20f37-a373-77f0-aa03-55d220067a32',
      'parentCategoryName': 'Abarrotes',
    });

    expect(category.id, '01a20f3b-28b1-7be8-8350-974136ee38b0');
    expect(category.name, 'Enlatados');
    expect(
      category.description,
      'Categoria de articulos enlatados, como salsa de tomate etc.',
    );
    expect(category.parentCategoryId, '01a20f37-a373-77f0-aa03-55d220067a32');
    expect(category.parentCategoryName, 'Abarrotes');
  });
}
