import 'dart:async';

import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/employees/data/employee_repository.dart';
import 'package:casca_app/features/employees/data/models/employee_models.dart';
import 'package:casca_app/features/employees/domain/employee_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int employeesPageSize = 10;

class EmployeeQuery {
  const EmployeeQuery({
    this.search = '',
    this.status = EmployeeStatusFilter.all,
    this.page = 1,
  });

  final String search;
  final EmployeeStatusFilter status;
  final int page;
}

class EmployeeQueryController extends Notifier<EmployeeQuery> {
  static const Duration searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  @override
  EmployeeQuery build() {
    ref.watch(authControllerProvider.select((s) => s.session?.activeStore.id));
    ref.onDispose(() => _searchTimer?.cancel());
    return const EmployeeQuery();
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final search = value.trim();
      if (search == state.search) return;
      state = EmployeeQuery(search: search, status: state.status);
    });
  }

  void setStatus(EmployeeStatusFilter status) {
    if (status == state.status) return;
    state = EmployeeQuery(search: state.search, status: status);
  }

  void setPage(int page) {
    if (page == state.page) return;
    state = EmployeeQuery(
      search: state.search,
      status: state.status,
      page: page,
    );
  }
}

final employeeQueryProvider =
    NotifierProvider.autoDispose<EmployeeQueryController, EmployeeQuery>(
      EmployeeQueryController.new,
    );

final employeeListProvider =
    FutureProvider.autoDispose<PagedResponse<EmployeeModel>>(
      retry: (_, _) => null,
      (ref) {
        final query = ref.watch(employeeQueryProvider);
        return ref
            .watch(employeeRepositoryProvider)
            .getEmployees(
              search: query.search,
              isActive: query.status.isActive,
              page: query.page,
              pageSize: employeesPageSize,
            );
      },
    );

final employeeDetailProvider = FutureProvider.autoDispose
    .family<EmployeeModel, String>(retry: (_, _) => null, (ref, id) {
      ref.watch(
        authControllerProvider.select((s) => s.session?.activeStore.id),
      );
      return ref.watch(employeeRepositoryProvider).getEmployee(id);
    });

final employeeRolesProvider =
    FutureProvider.autoDispose<List<EmployeeRoleOption>>(
      retry: (_, _) => null,
      (ref) => ref.watch(employeeRepositoryProvider).getRoles(),
    );

final cashRegisterAccessProvider = FutureProvider.autoDispose
    .family<List<CashRegisterAccess>, String>(
      retry: (_, _) => null,
      (ref, id) =>
          ref.watch(employeeRepositoryProvider).getCashRegisterAccess(id),
    );

class EmployeeActionController extends Notifier<AsyncValue<String?>> {
  EmployeeActionController(this.scope);

  final String scope;

  @override
  AsyncValue<String?> build() => const AsyncData(null);

  Future<bool> run(
    Future<String?> Function(EmployeeRepository repository) action, {
    String? employeeId,
  }) async {
    if (state.isLoading) return false;
    state = const AsyncLoading<String?>();
    final repository = ref.read(employeeRepositoryProvider);
    final link = ref.keepAlive();
    final result = await AsyncValue.guard(() => action(repository));
    if (ref.mounted) {
      if (!result.hasError) {
        ref.invalidate(employeeListProvider);
        if (employeeId != null) {
          ref.invalidate(employeeDetailProvider(employeeId));
        }
      }
      state = result;
    }
    link.close();
    return !result.hasError;
  }
}

final employeeActionProvider = NotifierProvider.autoDispose
    .family<EmployeeActionController, AsyncValue<String?>, String>(
      EmployeeActionController.new,
    );
