import 'package:casca_app/core/customers/customer_model.dart';
import 'package:casca_app/core/customers/customer_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerFormController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<CustomerModel?> create(Map<String, dynamic> request) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    final link = ref.keepAlive();
    final repository = ref.read(customerRepositoryProvider);
    final result = await AsyncValue.guard(
      () => repository.createCustomer(request),
    );
    if (ref.mounted) state = result;
    link.close();
    return result.value;
  }
}

final customerFormControllerProvider =
    NotifierProvider.autoDispose<CustomerFormController, AsyncValue<void>>(
      CustomerFormController.new,
    );
