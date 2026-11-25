import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/products/data/category_endpoints.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/data/models/category_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryRepository {
  const CategoryRepository(this._api);

  final ApiClient _api;

  Future<PagedResponse<CategoryModel>> getCategories({
    String search = '',
    int page = 1,
    int pageSize = 10,
    bool descending = false,
    bool rootOnly = false,
  }) {
    return _api.get<PagedResponse<CategoryModel>>(
      CategoryEndpoints.list,
      query: {
        if (search.isNotEmpty) 'searchTerm': search,
        'page': page,
        'pageSize': pageSize,
        'sort': 'name',
        'order': descending ? 'desc' : 'asc',
        if (rootOnly) 'rootOnly': true,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        CategoryModel.fromJson,
      ),
    );
  }

  Future<void> deleteCategory(String categoryId) {
    return _api.delete(CategoryEndpoints.byId(categoryId));
  }

  Future<void> createCategory(CategoryRequest request) {
    return _api.post<void>(
      CategoryEndpoints.list,
      body: request.toJson(),
      decode: (_) {},
    );
  }

  Future<void> updateCategory(String categoryId, CategoryRequest request) {
    return _api.put<void>(
      CategoryEndpoints.byId(categoryId),
      body: request.toJson(),
      decode: (_) {},
    );
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(apiClientProvider)),
);
