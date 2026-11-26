import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/data/models/sale_model.dart';
import 'package:casca_app/features/pos/data/pos_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int posPageSize = 50;
const String _noActiveShiftCode = 'CashRegister.NoActiveShift';

class PosRepository {
  PosRepository(this._api);

  final ApiClient _api;

  Future<PosCatalogPageModel> catalog(String search, int page) {
    return _api.get(
      PosEndpoints.catalog,
      query: {
        'q': search,
        'sort': 'name',
        'sortOrder': 'asc',
        'page': page,
        'pageSize': posPageSize,
      },
      decode: (data) =>
          PosCatalogPageModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<SalePreviewModel> preview(Map<String, dynamic> request) {
    return _api.post(
      PosEndpoints.salePreview,
      body: request,
      decode: (data) => SalePreviewModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<SaleResultModel> createSale(
    Map<String, dynamic> request, {
    required String idempotencyKey,
  }) {
    return _api.post(
      PosEndpoints.sales,
      body: request,
      headers: {'Idempotency-Key': idempotencyKey},
      decode: (data) => SaleResultModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<bool> hasActiveShift() async {
    try {
      return await _api.get(
        PosEndpoints.activeShift,
        decode: (data) => data != null,
      );
    } on ApiException catch (error) {
      if (error.hasCode(_noActiveShiftCode)) return false;
      rethrow;
    }
  }
}

final posRepositoryProvider = Provider<PosRepository>(
  (ref) => PosRepository(ref.watch(apiClientProvider)),
);
