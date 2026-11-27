class RoleListItemModel {
  const RoleListItemModel({
    required this.id,
    required this.name,
    required this.isSystem,
    this.description,
    this.permissionCount = 0,
    this.employeeCount = 0,
  });

  factory RoleListItemModel.fromJson(Map<String, dynamic> json) {
    return RoleListItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isSystem: json['isSystem'] as bool? ?? false,
      permissionCount: json['permissionCount'] as int? ?? 0,
      employeeCount: json['employeeCount'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String? description;
  final bool isSystem;
  final int permissionCount;
  final int employeeCount;
}

class RoleDetailModel {
  const RoleDetailModel({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.permissionKeys,
    this.description,
    this.employeeCount = 0,
  });

  factory RoleDetailModel.fromJson(Map<String, dynamic> json) {
    return RoleDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isSystem: json['isSystem'] as bool? ?? false,
      permissionKeys: (json['permissionKeys'] as List<Object?>? ?? const [])
          .cast<String>()
          .toSet(),
      employeeCount: json['employeeCount'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String? description;
  final bool isSystem;
  final Set<String> permissionKeys;
  final int employeeCount;
}

class PermissionModel {
  const PermissionModel({
    required this.key,
    required this.description,
    required this.grantable,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      key: json['key'] as String,
      description: json['description'] as String? ?? '',
      grantable: json['grantable'] as bool? ?? false,
    );
  }

  final String key;
  final String description;
  final bool grantable;
}

class PermissionGroupModel {
  const PermissionGroupModel({
    required this.key,
    required this.label,
    required this.permissions,
  });

  factory PermissionGroupModel.fromJson(Map<String, dynamic> json) {
    return PermissionGroupModel(
      key: json['key'] as String,
      label: json['label'] as String,
      permissions: [
        for (final item in json['permissions'] as List<Object?>)
          PermissionModel.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final String key;
  final String label;
  final List<PermissionModel> permissions;
}
