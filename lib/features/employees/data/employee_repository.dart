import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/employees/data/models/employee_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class EmployeeEndpoints {
  static const String employees = '/api/v1/employees';
  static const String roles = '$employees/roles';

  static String byId(String id) => '$employees/$id';
  static String role(String id) => '$employees/$id/role';
  static String activate(String id) => '$employees/$id/activate';
  static String deactivate(String id) => '$employees/$id/deactivate';
  static String cashRegisters(String id) => '$employees/$id/cash-registers';
  static String resendInvitation(String id) =>
      '$employees/$id/resend-invitation';
}

List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) fromJson) {
  return [
    for (final item in data as List<Object?>)
      fromJson(item as Map<String, dynamic>),
  ];
}

class EmployeeRepository {
  const EmployeeRepository(this._api);

  final ApiClient _api;

  Future<PagedResponse<EmployeeModel>> getEmployees({
    required int page,
    required int pageSize,
    String search = '',
    bool? isActive,
  }) {
    return _api.get(
      EmployeeEndpoints.employees,
      query: {
        if (search.isNotEmpty) 'q': search,
        'isActive': ?isActive,
        'sort': 'name',
        'order': 'asc',
        'page': page,
        'pageSize': pageSize,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        EmployeeModel.fromJson,
      ),
    );
  }

  Future<EmployeeModel> getEmployee(String id) {
    return _api.get(
      EmployeeEndpoints.byId(id),
      decode: (data) => EmployeeModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<EmployeeRoleOption>> getRoles() {
    return _api.get(
      EmployeeEndpoints.roles,
      decode: (data) => _list(data, EmployeeRoleOption.fromJson),
    );
  }

  Future<CreateEmployeeResult> createEmployee(Map<String, dynamic> request) {
    return _api.post(
      EmployeeEndpoints.employees,
      body: request,
      decode: (data) =>
          CreateEmployeeResult.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> request) {
    return _put(EmployeeEndpoints.byId(id), request);
  }

  Future<void> changeRole(String id, String roleId) {
    return _put(EmployeeEndpoints.role(id), {'roleId': roleId});
  }

  Future<void> setActive(String id, {required bool active}) {
    return _put(
      active
          ? EmployeeEndpoints.activate(id)
          : EmployeeEndpoints.deactivate(id),
    );
  }

  Future<bool> resendInvitation(String id) {
    return _api.post(
      EmployeeEndpoints.resendInvitation(id),
      decode: (data) =>
          (data as Map<String, dynamic>)['invitationSent'] == true,
    );
  }

  Future<List<CashRegisterAccess>> getCashRegisterAccess(String id) {
    return _api.get(
      EmployeeEndpoints.cashRegisters(id),
      decode: (data) => _list(data, CashRegisterAccess.fromJson),
    );
  }

  Future<void> updateCashRegisterAccess(String id, Set<String> registerIds) {
    return _put(EmployeeEndpoints.cashRegisters(id), {
      'cashRegisterIds': registerIds.toList(),
    });
  }

  Future<void> _put(String path, [Object? body]) {
    return _api.put<void>(path, body: body, decode: (_) {});
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>(
  (ref) => EmployeeRepository(ref.watch(apiClientProvider)),
);
