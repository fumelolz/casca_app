import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/cash_registers/data/models/cash_register_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class CashRegisterEndpoints {
  static const String list = '/api/v1/cash-registers';

  static String byId(String cashRegisterId) => '$list/$cashRegisterId';
}

class CashRegisterRepository {
  const CashRegisterRepository(this._api);

  final ApiClient _api;

  Future<PagedResponse<CashRegisterModel>> getCashRegisters({
    String search = '',
    bool? isOpen,
    int page = 1,
    int pageSize = 10,
    bool descending = false,
  }) {
    return _api.get<PagedResponse<CashRegisterModel>>(
      CashRegisterEndpoints.list,
      query: {
        if (search.isNotEmpty) 'q': search,
        'isOpen': ?isOpen,
        'sort': 'name',
        'order': descending ? 'desc' : 'asc',
        'page': page,
        'pageSize': pageSize,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        CashRegisterModel.fromJson,
      ),
    );
  }

  Future<void> createCashRegister(CashRegisterRequest request) {
    return _api.post<void>(
      CashRegisterEndpoints.list,
      body: request.toJson(),
      decode: (_) {},
    );
  }

  Future<void> updateCashRegister(
    String cashRegisterId,
    CashRegisterRequest request,
  ) {
    return _api.put<void>(
      CashRegisterEndpoints.byId(cashRegisterId),
      body: request.toJson(),
      decode: (_) {},
    );
  }

  Future<void> deleteCashRegister(String cashRegisterId) {
    return _api.delete(CashRegisterEndpoints.byId(cashRegisterId));
  }
}

final cashRegisterRepositoryProvider = Provider<CashRegisterRepository>(
  (ref) => CashRegisterRepository(ref.watch(apiClientProvider)),
);
