import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/cash_registers/data/models/shift_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class ShiftEndpoints {
  static const String list = '/api/v1/cash-registers/shifts';

  static String byId(String shiftId) => '$list/$shiftId';
}

class ShiftRepository {
  const ShiftRepository(this._api);

  final ApiClient _api;

  Future<PagedResponse<ShiftListItemModel>> getShifts({
    required int page,
    required int pageSize,
  }) {
    return _api.get(
      ShiftEndpoints.list,
      query: {
        'sort': 'openedAt',
        'order': 'desc',
        'page': page,
        'pageSize': pageSize,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        ShiftListItemModel.fromJson,
      ),
    );
  }

  Future<ShiftDetailModel> getShift(
    String shiftId, {
    required int movementsPage,
    required int salesPage,
    required int pageSize,
  }) {
    return _api.get(
      ShiftEndpoints.byId(shiftId),
      query: {
        'movementsPage': movementsPage,
        'movementsPageSize': pageSize,
        'salesPage': salesPage,
        'salesPageSize': pageSize,
      },
      decode: (data) => ShiftDetailModel.fromJson(data as Map<String, dynamic>),
    );
  }
}

final shiftRepositoryProvider = Provider<ShiftRepository>(
  (ref) => ShiftRepository(ref.watch(apiClientProvider)),
);
