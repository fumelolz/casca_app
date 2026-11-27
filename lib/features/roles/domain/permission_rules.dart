import 'package:casca_app/features/roles/data/models/role_models.dart';

const int maxRoleName = 50;
const int maxRoleDescription = 250;

Iterable<String> grantableKeys(PermissionGroupModel group) {
  return group.permissions
      .where((permission) => permission.grantable)
      .map((permission) => permission.key);
}

bool? groupValue(PermissionGroupModel group, Set<String> selected) {
  final grantable = grantableKeys(group).toList();
  final count = grantable.where(selected.contains).length;
  if (count == 0) return false;
  return count == grantable.length ? true : null;
}

Set<String> setGroup(
  PermissionGroupModel group,
  Set<String> selected, {
  required bool checked,
}) {
  final keys = grantableKeys(group).toSet();
  return checked ? selected.union(keys) : selected.difference(keys);
}

Set<String> togglePermission(
  Set<String> selected,
  String key, {
  required bool checked,
}) {
  return checked ? {...selected, key} : selected.difference({key});
}

List<PermissionGroupModel> filterGroups(
  List<PermissionGroupModel> groups,
  String term,
) {
  final needle = term.trim().toLowerCase();
  if (needle.isEmpty) return groups;
  bool matches(String text) => text.toLowerCase().contains(needle);

  return [
    for (final group in groups)
      if (group.permissions
              .where(
                (permission) =>
                    matches(group.label) ||
                    matches(permission.key) ||
                    matches(permission.description),
              )
              .toList()
          case final found when found.isNotEmpty)
        PermissionGroupModel(
          key: group.key,
          label: group.label,
          permissions: found,
        ),
  ];
}

bool sameSelection(Set<String> first, Set<String> second) {
  return first.length == second.length && first.containsAll(second);
}

Set<String> knownKeys(List<PermissionGroupModel> groups) {
  return {
    for (final group in groups)
      for (final permission in group.permissions) permission.key,
  };
}

Set<String> copyablePermissions(
  List<PermissionGroupModel> groups,
  Set<String> source,
) {
  return source.intersection(groups.expand(grantableKeys).toSet());
}

String copyName(String name) {
  final copy = 'Copia de $name';
  return copy.length > maxRoleName ? copy.substring(0, maxRoleName) : copy;
}

Map<String, dynamic> saveRoleRequest({
  required String name,
  required String description,
  required Set<String> permissionKeys,
}) {
  return {
    'name': name.trim(),
    'description': description.trim().isEmpty ? null : description.trim(),
    'permissionKeys': permissionKeys.toList()..sort(),
  };
}
