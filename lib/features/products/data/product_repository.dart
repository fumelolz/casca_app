import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/features/products/data/product_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProductSortField { created, name, stock }

class ProductRepository {
  const ProductRepository(this._api);

  final ApiClient _api;

  Future<ProductDetailModel> getProduct(String productId) {
    return _api.get<ProductDetailModel>(
      ProductEndpoints.byId(productId),
      decode: (data) =>
          ProductDetailModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<String> createProduct(Map<String, dynamic> request) {
    return _api.post<String>(
      ProductEndpoints.list,
      body: request,
      decode: (data) => (data as Map<String, dynamic>)['id'] as String,
    );
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> request) {
    return _api.put<void>(
      ProductEndpoints.byId(productId),
      body: request,
      decode: (_) {},
    );
  }

  Future<PagedResponse<ProductListItemModel>> getProducts({
    String search = '',
    int page = 1,
    int pageSize = 10,
    ProductSortField sort = ProductSortField.created,
    bool descending = true,
  }) {
    return _api.get<PagedResponse<ProductListItemModel>>(
      ProductEndpoints.list,
      query: {
        if (search.isNotEmpty) 'q': search,
        'sort': sort.name,
        'order': descending ? 'desc' : 'asc',
        'page': page,
        'pageSize': pageSize,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        ProductListItemModel.fromJson,
      ),
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(apiClientProvider)),
);
