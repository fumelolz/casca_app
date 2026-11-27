import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/core/customers/customer_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class CustomerEndpoints {
  static const String customers = '/api/v1/customers';

  static String email(String id) => '$customers/$id/email';

  static String resendConfirmation(String id) =>
      '$customers/$id/resend-confirmation';
}

bool _emailSent(Object? data) {
  return (data as Map<String, dynamic>)['confirmationEmailSent'] == true;
}

class CustomerRepository {
  const CustomerRepository(this._api);

  final ApiClient _api;

  Future<PagedResponse<CustomerModel>> getCustomers({
    required int page,
    required int pageSize,
    String search = '',
    String? status,
  }) {
    return _api.get(
      CustomerEndpoints.customers,
      query: {
        if (search.isNotEmpty) 'searchTerm': search,
        'status': ?status,
        'page': page,
        'pageSize': pageSize,
      },
      decode: (data) => PagedResponse.fromJson(
        data as Map<String, dynamic>,
        CustomerModel.fromJson,
      ),
    );
  }

  Future<CustomerModel> createCustomer(Map<String, dynamic> request) {
    return _api.post(
      CustomerEndpoints.customers,
      body: request,
      decode: (data) => CustomerModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<bool> correctEmail(String id, String email) {
    return _api.put(
      CustomerEndpoints.email(id),
      body: {'email': email},
      decode: _emailSent,
    );
  }

  Future<bool> resendConfirmation(String id) {
    return _api.post(
      CustomerEndpoints.resendConfirmation(id),
      decode: _emailSent,
    );
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepository(ref.watch(apiClientProvider)),
);
