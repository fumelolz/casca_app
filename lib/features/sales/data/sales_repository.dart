import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/sales/data/models/sale_history_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SaleSortField {
  saleNumber('saleNumber'),
  status('status'),
  paymentMethod('paymentMethod'),
  created('createdOnUtc');

  const SaleSortField(this.query);

  final String query;
}

abstract final class SalesHistoryEndpoints {
  static const String list = '/api/v1/sales';

  static String byId(String saleId) => '$list/$saleId';
}

class SalesRepository {
  const SalesRepository(this._api);

  final ApiClient _api;

  Future<PagedResponse<SaleListItemModel>> getSales({
    required int page,
    required int pageSize,
    String search = '',
    SaleSortField sort = SaleSortField.created,
    bool descending = true,
  }) {
    final term = search.trim();
    return _api.get(
      SalesHistoryEndpoints.list,
      query: {
        'sort': sort.query,
        'order': descending ? 'desc' : 'asc',
        'page': page,
        'pageSize': pageSize,
        if (term.isNotEmpty) 'q': term,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        SaleListItemModel.fromJson,
      ),
    );
  }

  Future<SaleDetailModel> getSale(String saleId) {
    return _api.get(
      SalesHistoryEndpoints.byId(saleId),
      decode: (data) => SaleDetailModel.fromJson(data as Map<String, dynamic>),
    );
  }
}

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepository(ref.watch(apiClientProvider)),
);
