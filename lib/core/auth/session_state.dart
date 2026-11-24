class SessionAccount {
  const SessionAccount({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
  });

  factory SessionAccount.fromJson(Map<String, dynamic> json) {
    return SessionAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );
  }

  final String id;
  final String email;
  final String name;
  final String? phone;
}

class SessionRole {
  const SessionRole({required this.id, required this.name});

  factory SessionRole.fromJson(Map<String, dynamic> json) {
    return SessionRole(id: json['id'] as String, name: json['name'] as String);
  }

  final String id;
  final String name;
}

class SessionStore {
  const SessionStore({
    required this.id,
    required this.name,
    required this.taxesEnabled,
    required this.isDefault,
    required this.tenantId,
    required this.tenantName,
    this.businessType,
  });

  factory SessionStore.fromJson(Map<String, dynamic> json) {
    return SessionStore(
      id: json['id'] as String,
      name: json['name'] as String,
      taxesEnabled: json['taxesEnabled'] as bool,
      isDefault: json['isDefault'] as bool,
      tenantId: json['tenantId'] as String,
      tenantName: json['tenantName'] as String,
      businessType: json['businessType'] as String?,
    );
  }

  final String id;
  final String name;
  final bool taxesEnabled;
  final bool isDefault;
  final String tenantId;
  final String tenantName;
  final String? businessType;
}

class SessionState {
  const SessionState({
    required this.account,
    required this.stores,
    required this.roles,
    required this.permissions,
    required this.hasTenant,
    required this.hasCompletedOnboarding,
    this.activeStore,
    this.tenantName,
  });

  factory SessionState.fromJson(Map<String, dynamic> json) {
    return SessionState(
      account: SessionAccount.fromJson(json['account'] as Map<String, dynamic>),
      activeStore: _storeFromJson(json['store']),
      stores: (json['stores'] as List<dynamic>? ?? const [])
          .map((store) => SessionStore.fromJson(store as Map<String, dynamic>))
          .toList(),
      roles: (json['roles'] as List<dynamic>)
          .map((role) => SessionRole.fromJson(role as Map<String, dynamic>))
          .toList(),
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .cast<String>(),
      hasTenant: json['hasTenant'] as bool,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool,
      tenantName: json['tenantName'] as String?,
    );
  }

  static SessionStore? _storeFromJson(Object? json) {
    if (json == null) return null;
    return SessionStore.fromJson(json as Map<String, dynamic>);
  }

  final SessionAccount account;
  final SessionStore? activeStore;
  final List<SessionStore> stores;
  final List<SessionRole> roles;
  final List<String> permissions;
  final bool hasTenant;
  final bool hasCompletedOnboarding;
  final String? tenantName;

  bool hasPermission(String permission) => permissions.contains(permission);

  bool hasAnyPermission(Iterable<String> candidates) {
    return candidates.any(permissions.contains);
  }
}
