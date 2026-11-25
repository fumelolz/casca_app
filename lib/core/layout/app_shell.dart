import 'dart:math' as math;

import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/layout/mobile_bottom_bar.dart';
import 'package:casca_app/core/layout/preferences_nav.dart';
import 'package:casca_app/core/layout/sidebar.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/core/layout/topbar.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _drawerMaxWidth = 300;
const double _drawerWidthFactor = 0.85;
const Color _backdropColor = Color(0x520F172A);
const Duration _transition = Duration(milliseconds: 250);
const double _edgeSwipeWidth = 20;
const double _edgeSwipeThreshold = 6;
const double _swipeCloseVelocity = 300;

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final sidebar = ref.watch(sidebarProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= mobileBreakpoint;

        if (!isMobile && sidebar.mobileOpen) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => ref.read(sidebarProvider.notifier).closeMobile(),
          );
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                ref.read(sidebarProvider.notifier).closeMobile(),
          },
          child: Material(
            color: colors.background,
            child: isMobile
                ? _buildMobile(context, ref, sidebar, constraints.maxWidth)
                : _buildDesktop(sidebar),
          ),
        );
      },
    );
  }

  Widget _buildPage({required bool isMobile}) {
    final page = Expanded(
      child: ClipRect(
        child: isMobile
            ? SafeArea(top: false, bottom: false, child: child)
            : child,
      ),
    );

    return isMobile
        ? Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PreferencesNav(location: location, isMobile: true),
                page,
              ],
            ),
          )
        : Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PreferencesNav(location: location, isMobile: false),
                page,
              ],
            ),
          );
  }

  Widget _buildDesktop(SidebarState sidebar) {
    final width = sidebar.collapsed ? sidebarCompactWidth : sidebarWidth;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: _transition,
          curve: Curves.ease,
          width: width,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: width,
              maxWidth: width,
              child: Sidebar(
                location: location,
                compact: sidebar.collapsed,
                isMobile: false,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Topbar(isMobile: false),
              _buildPage(isMobile: false),
            ],
          ),
        ),
      ],
    );
  }

  void _closeOnSwipeLeft(WidgetRef ref, DragEndDetails details) {
    if ((details.primaryVelocity ?? 0) < -_swipeCloseVelocity) {
      ref.read(sidebarProvider.notifier).closeMobile();
    }
  }

  Widget _buildMobile(
    BuildContext context,
    WidgetRef ref,
    SidebarState sidebar,
    double screenWidth,
  ) {
    final drawerWidth = math.min(
      _drawerMaxWidth,
      screenWidth * _drawerWidthFactor,
    );
    final open = sidebar.mobileOpen;
    final insets = MediaQuery.paddingOf(context);
    final showBar = !AppRoutes.isFormRoute(location);
    final barExtent = showBar ? mobileBottomBarExtent(insets.bottom) : 0.0;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Topbar(isMobile: true, insets: insets),
            _buildPage(isMobile: true),
            SizedBox(height: math.max(barExtent, keyboard)),
          ],
        ),
        if (showBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MobileBottomBar(
              location: location,
              bottomInset: insets.bottom,
            ),
          ),
        if (open)
          Positioned(
            top: topbarHeight + insets.top,
            left: 0,
            right: 0,
            bottom: 0,
            child: Semantics(
              button: true,
              label: 'Cerrar menú de navegación',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: ref.read(sidebarProvider.notifier).closeMobile,
                onHorizontalDragEnd: (details) =>
                    _closeOnSwipeLeft(ref, details),
                child: const ColoredBox(color: _backdropColor),
              ),
            ),
          ),
        if (!open)
          Positioned(
            top: topbarHeight + insets.top,
            left: 0,
            bottom: 0,
            width: _edgeSwipeWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > _edgeSwipeThreshold) {
                  ref.read(sidebarProvider.notifier).openMobile();
                }
              },
            ),
          ),
        AnimatedPositioned(
          duration: _transition,
          curve: Curves.ease,
          top: topbarHeight + insets.top,
          bottom: 0,
          left: open ? 0 : -drawerWidth,
          width: drawerWidth,
          child: ExcludeFocus(
            excluding: !open,
            child: ExcludeSemantics(
              excluding: !open,
              child: IgnorePointer(
                ignoring: !open,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) =>
                      _closeOnSwipeLeft(ref, details),
                  child: Sidebar(
                    location: location,
                    compact: false,
                    isMobile: true,
                    bottomInset: insets.bottom,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
