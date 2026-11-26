import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/price_lists/data/models/price_list_model.dart';
import 'package:casca_app/features/price_lists/data/price_list_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PriceListRepository {
  PriceListRepository(this._api);

  final ApiClient _api;

  static PriceListModel _list(Object? data) {
    return PriceListModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PriceListModel>> getAll() {
    return _api.get(
      PriceListEndpoints.list,
      decode: (data) => [for (final item in data as List<Object?>) _list(item)],
    );
  }

  Future<PriceListModel> getById(String priceListId) {
    return _api.get(PriceListEndpoints.byId(priceListId), decode: _list);
  }

  Future<PriceListModel> create(String name) {
    return _api.post(
      PriceListEndpoints.list,
      body: {'name': name},
      decode: _list,
    );
  }

  Future<PriceListModel> rename(String priceListId, String name) {
    return _api.put(
      PriceListEndpoints.byId(priceListId),
      body: {'name': name},
      decode: _list,
    );
  }

  Future<void> delete(String priceListId) {
    return _api.delete(PriceListEndpoints.byId(priceListId));
  }

  Future<Map<String, double>> getPrices(String priceListId) {
    return _api.get(
      PriceListEndpoints.prices(priceListId),
      decode: (data) => {
        for (final item in data as List<Object?>)
          if (item case {
            'sellableItemId': final String id,
            'price': final num price,
          })
            id: price.toDouble(),
      },
    );
  }

  Future<void> setPrices(
    String priceListId,
    List<Map<String, Object?>> prices,
  ) {
    return _api.put(
      PriceListEndpoints.prices(priceListId),
      body: {'prices': prices},
      decode: (_) {},
    );
  }

  Future<PagedResponse<PriceListItemModel>> getItems({
    required String search,
    required int page,
    required int pageSize,
  }) {
    return _api.get(
      PriceListEndpoints.sellableItems,
      query: {
        'q': search,
        'sort': 'name',
        'sortOrder': 'asc',
        'page': page,
        'pageSize': pageSize,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        PriceListItemModel.fromJson,
      ),
    );
  }
}

final priceListRepositoryProvider = Provider<PriceListRepository>(
  (ref) => PriceListRepository(ref.watch(apiClientProvider)),
);
