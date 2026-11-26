import 'package:casca_app/core/auth/session_state.dart';

const String _administratorRole = 'Administrador';

class BusinessGroup {
  const BusinessGroup({
    required this.tenantId,
    required this.tenantName,
    required this.isActive,
    required this.stores,
    this.businessType,
  });

  final String tenantId;
  final String tenantName;
  final String? businessType;
  final bool isActive;
  final List<SessionStore> stores;
}

List<BusinessGroup> groupBusinesses(SessionState session) {
  final byTenant = <String, List<SessionStore>>{};
  for (final store in session.stores) {
    byTenant.putIfAbsent(store.tenantId, () => []).add(store);
  }

  return [
    for (final stores in byTenant.values)
      BusinessGroup(
        tenantId: stores.first.tenantId,
        tenantName: stores.first.tenantName,
        businessType: stores.first.businessType,
        isActive: stores.first.tenantId == session.activeStore.tenantId,
        stores: stores,
      ),
  ];
}

bool canCreateBusiness(SessionState session) {
  return session.roles.any((role) => role.name == _administratorRole);
}

String businessInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'))
    ..removeWhere((word) => word.isEmpty);
  if (words.isEmpty) return '?';

  final letters = words.length > 1
      ? '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
      : words[0].substring(0, words[0].length < 2 ? words[0].length : 2);
  return letters.toUpperCase();
}

String linkedStoresLabel(int count) {
  return count == 1 ? '1 sucursal vinculada' : '$count sucursales vinculadas';
}
