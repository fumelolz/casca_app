import 'dart:async';

import 'package:casca_app/core/storage/preferences_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double mobileBreakpoint = 768;

class SidebarState {
  const SidebarState({this.collapsed = false, this.mobileOpen = false});

  final bool collapsed;
  final bool mobileOpen;

  SidebarState copyWith({bool? collapsed, bool? mobileOpen}) {
    return SidebarState(
      collapsed: collapsed ?? this.collapsed,
      mobileOpen: mobileOpen ?? this.mobileOpen,
    );
  }
}

class SidebarController extends Notifier<SidebarState> {
  bool _chosen = false;

  @override
  SidebarState build() {
    _restore();
    return const SidebarState();
  }

  void toggle() => setCollapsed(!state.collapsed);

  void setCollapsed(bool collapsed) {
    _chosen = true;
    state = state.copyWith(collapsed: collapsed);
    unawaited(
      ref
          .read(preferencesStorageProvider)
          .write(PreferencesStorage.sidebarCollapsedKey, '$collapsed'),
    );
  }

  Future<void> _restore() async {
    final stored = await ref
        .read(preferencesStorageProvider)
        .read(PreferencesStorage.sidebarCollapsedKey);
    if (!ref.mounted || _chosen || stored == null) return;
    state = state.copyWith(collapsed: stored == 'true');
  }

  void toggleMobile() => state = state.copyWith(mobileOpen: !state.mobileOpen);

  void openMobile() {
    if (!state.mobileOpen) state = state.copyWith(mobileOpen: true);
  }

  void closeMobile() {
    if (state.mobileOpen) state = state.copyWith(mobileOpen: false);
  }
}

final sidebarProvider = NotifierProvider<SidebarController, SidebarState>(
  SidebarController.new,
);
