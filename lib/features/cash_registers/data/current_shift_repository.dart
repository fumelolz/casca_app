import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/cash_registers/data/models/current_shift_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _noActiveShiftCode = 'CashRegister.NoActiveShift';

enum CashMovementType {
  deposit('deposit'),
  withdrawal('withdrawal');

  const CashMovementType(this.path);

  final String path;
}

abstract final class CurrentShiftEndpoints {
  static const String _base = '/api/v1/cash-registers';
  static const String active = '$_base/active';
  static const String available = '$_base/available';

  static String open(String cashRegisterId) => '$_base/$cashRegisterId/open';

  static String movement(String shiftId, CashMovementType type) =>
      '$_base/shifts/$shiftId/cash-movements/${type.path}';

  static String close(String shiftId) => '$_base/shifts/$shiftId/close';
}

class CurrentShiftRepository {
  const CurrentShiftRepository(this._api);

  final ApiClient _api;

  Future<CurrentShiftModel?> getCurrent() async {
    try {
      return await _api.get(
        CurrentShiftEndpoints.active,
        decode: (data) =>
            CurrentShiftModel.fromJson(data as Map<String, dynamic>),
      );
    } on ApiException catch (error) {
      if (error.hasCode(_noActiveShiftCode)) return null;
      rethrow;
    }
  }

  Future<List<AvailableCashRegisterModel>> getAvailableRegisters() {
    return _api.get(
      CurrentShiftEndpoints.available,
      decode: (data) => [
        for (final item in data as List<Object?>)
          AvailableCashRegisterModel.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  Future<void> open(
    String cashRegisterId, {
    required double initialAmount,
    String? notes,
  }) {
    return _api.postVoid(
      CurrentShiftEndpoints.open(cashRegisterId),
      body: {'initialAmount': initialAmount, 'notes': notes},
    );
  }

  Future<void> addMovement(
    String shiftId,
    CashMovementType type, {
    required double amount,
    required String notes,
  }) {
    return _api.postVoid(
      CurrentShiftEndpoints.movement(shiftId, type),
      body: {'amount': amount, 'notes': notes},
    );
  }

  Future<ClosedShiftModel> close(
    String shiftId, {
    required double countedCash,
    required String? notes,
    required double withdrawnAtClose,
    required Map<int, double> paymentCounts,
  }) {
    return _api.post(
      CurrentShiftEndpoints.close(shiftId),
      body: {
        'countedCash': countedCash,
        'notes': notes,
        'withdrawnAtClose': withdrawnAtClose,
        'paymentCounts': [
          for (final count in paymentCounts.entries)
            {'method': count.key, 'countedAmount': count.value},
        ],
      },
      decode: (data) => ClosedShiftModel.fromJson(data as Map<String, dynamic>),
    );
  }
}

final currentShiftRepositoryProvider = Provider<CurrentShiftRepository>(
  (ref) => CurrentShiftRepository(ref.watch(apiClientProvider)),
);
