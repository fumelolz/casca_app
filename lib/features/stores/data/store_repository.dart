import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/stores/data/models/store_list_item_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class StoreEndpoints {
  static const String list = '/api/v1/stores';

  static String byId(String storeId) => '$list/$storeId';
}

class StoreRepository {
  const StoreRepository(this._api);

  final ApiClient _api;

  Future<PagedResponse<StoreListItemModel>> getStores({
    String search = '',
    bool? isActive,
    int page = 1,
    int pageSize = 10,
    bool descending = false,
  }) {
    return _api.get<PagedResponse<StoreListItemModel>>(
      StoreEndpoints.list,
      query: {
        if (search.isNotEmpty) 'searchTerm': search,
        'isActive': ?isActive,
        'sortColumn': 'name',
        'sortOrder': descending ? 'desc' : 'asc',
        'page': page,
        'pageSize': pageSize,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        StoreListItemModel.fromJson,
      ),
    );
  }

  Future<Map<String, dynamic>> getStore(String storeId) {
    return _api.get<Map<String, dynamic>>(
      StoreEndpoints.byId(storeId),
      decode: (data) => data as Map<String, dynamic>,
    );
  }

  Future<void> createStore(Map<String, dynamic> request) {
    return _api.post<void>(StoreEndpoints.list, body: request, decode: (_) {});
  }

  Future<void> updateStore(String storeId, Map<String, dynamic> request) {
    return _api.put<void>(
      StoreEndpoints.byId(storeId),
      body: request,
      decode: (_) {},
    );
  }
}

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => StoreRepository(ref.watch(apiClientProvider)),
);
