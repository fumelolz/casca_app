class NavigationItem {
  const NavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    this.route,
    this.badge,
    this.permission,
    this.anyPermission,
    this.section,
    this.children,
    this.matchPrefixes,
  });

  final String id;
  final String label;
  final String icon;
  final String? route;
  final int? badge;
  final String? permission;
  final List<String>? anyPermission;
  final String? section;
  final List<NavigationItem>? children;
  final List<String>? matchPrefixes;

  bool get hasChildren => children != null && children!.isNotEmpty;

  NavigationItem copyWith({int? badge, List<NavigationItem>? children}) {
    return NavigationItem(
      id: id,
      label: label,
      icon: icon,
      route: route,
      badge: badge ?? this.badge,
      permission: permission,
      anyPermission: anyPermission,
      section: section,
      children: children ?? this.children,
      matchPrefixes: matchPrefixes,
    );
  }
}

class NavigationSection {
  const NavigationSection({required this.label, required this.items});

  final String label;
  final List<NavigationItem> items;
}

bool isRouteActive(String location, String route, {bool exact = false}) {
  if (location == route) return true;
  return !exact && location.startsWith('$route/');
}

bool isItemActive(String location, NavigationItem item) {
  final prefixes = item.matchPrefixes;
  if (prefixes != null) {
    return prefixes.any((prefix) => isRouteActive(location, prefix));
  }
  final route = item.route;
  return route != null && isRouteActive(location, route);
}
