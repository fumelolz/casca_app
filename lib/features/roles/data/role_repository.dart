import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/roles/data/models/role_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class RoleEndpoints {
  static const String roles = '/api/v1/roles';
  static const String permissions = '$roles/permissions';

  static String byId(String id) => '$roles/$id';
}

List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) fromJson) {
  return [
    for (final item in data as List<Object?>)
      fromJson(item as Map<String, dynamic>),
  ];
}

class RoleRepository {
  const RoleRepository(this._api);

  final ApiClient _api;

  Future<List<RoleListItemModel>> getRoles() {
    return _api.get(
      RoleEndpoints.roles,
      decode: (data) => _list(data, RoleListItemModel.fromJson),
    );
  }

  Future<List<PermissionGroupModel>> getPermissions() {
    return _api.get(
      RoleEndpoints.permissions,
      decode: (data) => _list(data, PermissionGroupModel.fromJson),
    );
  }

  Future<RoleDetailModel> getRole(String id) {
    return _api.get(
      RoleEndpoints.byId(id),
      decode: (data) => RoleDetailModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> createRole(Map<String, dynamic> request) {
    return _api.postVoid(RoleEndpoints.roles, body: request);
  }

  Future<void> updateRole(String id, Map<String, dynamic> request) {
    return _api.put<void>(
      RoleEndpoints.byId(id),
      body: request,
      decode: (_) {},
    );
  }

  Future<void> deleteRole(String id) => _api.delete(RoleEndpoints.byId(id));
}

final roleRepositoryProvider = Provider<RoleRepository>(
  (ref) => RoleRepository(ref.watch(apiClientProvider)),
);
