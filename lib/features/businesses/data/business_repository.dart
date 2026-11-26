import 'package:casca_app/core/auth/register_request.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/businesses/data/models/invitation_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class BusinessEndpoints {
  static const String switchStore = '/api/v1/auth/switch-store';
  static const String create = '/api/v1/auth/businesses';
  static const String invitations = '/api/v1/invitations';

  static String accept(String invitationId) =>
      '$invitations/$invitationId/accept';

  static String decline(String invitationId) =>
      '$invitations/$invitationId/decline';
}

class BusinessRepository {
  const BusinessRepository(this._api);

  final ApiClient _api;

  Future<SessionState> switchStore(String storeId) {
    return _api.post(
      BusinessEndpoints.switchStore,
      body: {'storeId': storeId},
      decode: _decodeSession,
    );
  }

  Future<SessionState> createBusiness({
    required String name,
    required BusinessType businessType,
  }) {
    return _api.post(
      BusinessEndpoints.create,
      body: {'name': name, 'businessType': businessType.name},
      decode: _decodeSession,
    );
  }

  Future<List<InvitationModel>> getInvitations() {
    return _api.get(
      BusinessEndpoints.invitations,
      decode: (data) => [
        for (final item in data as List<Object?>)
          InvitationModel.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  Future<void> acceptInvitation(String invitationId) {
    return _api.postVoid(BusinessEndpoints.accept(invitationId));
  }

  Future<void> declineInvitation(String invitationId) {
    return _api.postVoid(BusinessEndpoints.decline(invitationId));
  }

  static SessionState _decodeSession(Object? data) {
    return SessionState.fromJson(data as Map<String, dynamic>);
  }
}

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(apiClientProvider)),
);
