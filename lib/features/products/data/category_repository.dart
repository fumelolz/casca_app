import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/products/data/category_endpoints.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryRepository {
  const CategoryRepository(this._api);

  final ApiClient _api;

  Future<PagedResponse<CategoryModel>> getCategories({
    String search = '',
    int page = 1,
    int pageSize = 10,
  }) {
    return _api.get<PagedResponse<CategoryModel>>(
      CategoryEndpoints.list,
      query: {
        if (search.isNotEmpty) 'q': search,
        'sort': 'name',
        'order': 'asc',
        'page': page,
        'pageSize': pageSize,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        CategoryModel.fromJson,
      ),
    );
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(apiClientProvider)),
);
