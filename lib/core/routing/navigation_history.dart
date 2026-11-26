import 'package:casca_app/core/routing/app_routes.dart';

class NavigationHistory {
  final List<String> _entries = [];

  String? get previous {
    if (_entries.length > 1) return _entries[_entries.length - 2];
    final atHome = _entries.isEmpty || _entries.last == AppRoutes.home;
    return atHome ? null : AppRoutes.home;
  }

  void visit(String location) {
    final index = _entries.indexOf(location);
    if (index >= 0) {
      _entries.removeRange(index + 1, _entries.length);
      return;
    }
    _entries
      ..removeWhere(AppRoutes.isFormRoute)
      ..add(location);
  }
}
