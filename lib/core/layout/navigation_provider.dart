import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/auth/session_state.dart';
import 'package:casca_app/core/layout/navigation_item.dart';
import 'package:casca_app/core/layout/navigation_items.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationState {
  const NavigationState({
    required this.sections,
    required this.preferences,
    required this.preferenceGroups,
    required this.mobileTabs,
  });

  final List<NavigationSection> sections;
  final List<NavigationItem> preferences;
  final List<NavigationSection> preferenceGroups;
  final List<NavigationItem> mobileTabs;
}

bool _allowed(NavigationItem item, SessionState? session) {
  if (session == null) return false;
  final permission = item.permission;
  if (permission != null && !session.hasPermission(permission)) return false;
  final any = item.anyPermission;
  return any == null || session.hasAnyPermission(any);
}

NavigationItem? _visible(NavigationItem item, SessionState? session) {
  if (!_allowed(item, session)) return null;
  if (!item.hasChildren) return item;

  final children = item.children!
      .where((child) => _allowed(child, session))
      .toList();
  return children.isEmpty ? null : item.copyWith(children: children);
}

List<NavigationSection> _group(
  List<NavigationItem> items,
  String fallbackLabel,
) {
  final sections = <NavigationSection>[];
  for (final item in items) {
    final label = item.section ?? fallbackLabel;
    final index = sections.indexWhere((section) => section.label == label);
    if (index == -1) {
      sections.add(NavigationSection(label: label, items: [item]));
    } else {
      sections[index].items.add(item);
    }
  }
  return sections;
}

NavigationState buildNavigation(SessionState? session) {
  final modules = [
    for (final item in navigationModules) ?_visible(item, session),
  ];
  final preferences = [
    for (final item in preferenceModules) ?_visible(item, session),
  ];

  return NavigationState(
    sections: _group(modules, ''),
    preferences: preferences,
    preferenceGroups: _group(preferences, ''),
    mobileTabs: _centerPos([
      for (final item in mobileTabModules)
        if (_allowed(item, session)) item,
    ]),
  );
}

List<NavigationItem> _centerPos(List<NavigationItem> tabs) {
  final pos = tabs.where((tab) => tab.id == posTabId).firstOrNull;
  if (pos == null) return tabs;

  final others = tabs.where((tab) => tab.id != posTabId).toList();
  return [...others]..insert(tabs.length ~/ 2, pos);
}

final navigationProvider = Provider<NavigationState>((ref) {
  final session = ref.watch(authControllerProvider.select((s) => s.session));
  return buildNavigation(session);
});
