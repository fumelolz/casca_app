import 'dart:async';

import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/core/customers/customer_repository.dart';
import 'package:casca_app/core/customers/customer_model.dart';
import 'package:casca_app/core/customers/customer_rules.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int customersPageSize = 10;

class CustomerQuery {
  const CustomerQuery({
    this.search = '',
    this.status = CustomerStatusFilter.all,
    this.page = 1,
  });

  final String search;
  final CustomerStatusFilter status;
  final int page;
}

class CustomerQueryController extends Notifier<CustomerQuery> {
  static const Duration searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  @override
  CustomerQuery build() {
    ref.watch(authControllerProvider.select((s) => s.session?.activeStore.id));
    ref.onDispose(() => _searchTimer?.cancel());
    return const CustomerQuery();
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final search = value.trim();
      if (search == state.search) return;
      state = CustomerQuery(search: search, status: state.status);
    });
  }

  void setStatus(CustomerStatusFilter status) {
    if (status == state.status) return;
    state = CustomerQuery(search: state.search, status: status);
  }

  void setPage(int page) {
    if (page == state.page) return;
    state = CustomerQuery(
      search: state.search,
      status: state.status,
      page: page,
    );
  }
}

final customerQueryProvider =
    NotifierProvider.autoDispose<CustomerQueryController, CustomerQuery>(
      CustomerQueryController.new,
    );

final customerListProvider =
    FutureProvider.autoDispose<PagedResponse<CustomerModel>>(
      retry: (_, _) => null,
      (ref) {
        final query = ref.watch(customerQueryProvider);
        return ref
            .watch(customerRepositoryProvider)
            .getCustomers(
              search: query.search,
              status: query.status.value,
              page: query.page,
              pageSize: customersPageSize,
            );
      },
    );

class ConfirmationResult {
  const ConfirmationResult({required this.emailSent, this.correctedEmail});

  final bool emailSent;
  final String? correctedEmail;
}

class CustomerConfirmationController
    extends Notifier<AsyncValue<ConfirmationResult?>> {
  CustomerConfirmationController(this.customerId);

  final String customerId;

  @override
  AsyncValue<ConfirmationResult?> build() => const AsyncData(null);

  Future<bool> resend() {
    return _run((repository) => repository.resendConfirmation(customerId));
  }

  Future<bool> correctEmail(String email) {
    return _run(
      (repository) => repository.correctEmail(customerId, email),
      correctedEmail: email,
    );
  }

  Future<bool> _run(
    Future<bool> Function(CustomerRepository repository) send, {
    String? correctedEmail,
  }) async {
    if (state.isLoading) return false;
    final email = correctedEmail ?? state.value?.correctedEmail;
    final repository = ref.read(customerRepositoryProvider);
    final link = ref.keepAlive();
    state = const AsyncLoading<ConfirmationResult?>();
    final result = await AsyncValue.guard<ConfirmationResult?>(() async {
      return ConfirmationResult(
        emailSent: await send(repository),
        correctedEmail: email,
      );
    });
    if (ref.mounted) {
      if (!result.hasError) ref.invalidate(customerListProvider);
      state = result;
    }
    link.close();
    return !result.hasError;
  }
}

final customerConfirmationProvider = NotifierProvider.autoDispose
    .family<
      CustomerConfirmationController,
      AsyncValue<ConfirmationResult?>,
      String
    >(CustomerConfirmationController.new);
