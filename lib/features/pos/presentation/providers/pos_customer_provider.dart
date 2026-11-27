import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/customers/customer_model.dart';
import 'package:casca_app/core/customers/customer_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _searchPageSize = 10;
const Duration customerSearchDelay = Duration(milliseconds: 300);

class SaleCustomerController extends Notifier<CustomerModel?> {
  @override
  CustomerModel? build() {
    ref.watch(
      authControllerProvider.select(
        (s) => (s.session?.account.id, s.session?.activeStore.id),
      ),
    );
    return null;
  }

  void select(CustomerModel? customer) => state = customer;
}

final saleCustomerProvider =
    NotifierProvider<SaleCustomerController, CustomerModel?>(
      SaleCustomerController.new,
    );

final customerSearchProvider = FutureProvider.autoDispose
    .family<List<CustomerModel>, String>(retry: (_, _) => null, (
      ref,
      term,
    ) async {
      var cancelled = false;
      ref.onDispose(() => cancelled = true);
      if (term.isNotEmpty) await Future<void>.delayed(customerSearchDelay);
      if (cancelled) return const [];

      final page = await ref
          .read(customerRepositoryProvider)
          .getCustomers(search: term, page: 1, pageSize: _searchPageSize);
      return page.items;
    });
