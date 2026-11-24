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
  @override
  SidebarState build() => const SidebarState();

  void toggle() => state = state.copyWith(collapsed: !state.collapsed);

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
