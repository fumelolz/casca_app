import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/layout/brand_lockup.dart';
import 'package:casca_app/core/layout/navigation_item.dart';
import 'package:casca_app/core/layout/navigation_provider.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_popover.dart';
import 'package:casca_app/shared/ui/casca_tooltip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double sidebarWidth = 240;
const double sidebarCompactWidth = 64;
const double topbarHeight = 64;

const double _itemHeight = CascaSpacing.space8;
const double _subItemHeight = 38;
const double _subGap = 4;
const double _compactItemSize = CascaSpacing.space8;
const double _expandedIconBox = 20;
const double _expandedIconSize = 20;
const double _compactIconSize = 22;
const double _flyoutMinWidth = 224;
const double _flyoutIconSize = 16;
const double _submenuIndent = CascaSpacing.space3 + 10;
const double _treeGap = CascaSpacing.space3;

class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({
    super.key,
    required this.location,
    required this.compact,
    required this.isMobile,
    this.bottomInset = 0,
  });

  final String location;
  final bool compact;
  final bool isMobile;
  final double bottomInset;

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _expandActiveGroups();
  }

  @override
  void didUpdateWidget(Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _expandActiveGroups();
  }

  bool _hasActiveChild(NavigationItem item) {
    return item.children?.any(
          (child) =>
              child.route != null &&
              isRouteActive(widget.location, child.route!, exact: true),
        ) ??
        false;
  }

  void _expandActiveGroups() {
    final nav = ref.read(navigationProvider);
    for (final section in nav.sections) {
      for (final item in section.items) {
        if (_hasActiveChild(item)) _expanded.add(item.id);
      }
    }
  }

  void _toggle(String id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }

  void _navigate(String route) {
    ref.read(sidebarProvider.notifier).closeMobile();
    context.go(route);
  }

  bool get _preferencesActive {
    final nav = ref.read(navigationProvider);
    if (widget.location == AppRoutes.preferences) return true;
    return nav.preferences.any(
      (item) =>
          item.route != null && isRouteActive(widget.location, item.route!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final nav = ref.watch(navigationProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSidebar,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isMobile) _Brand(compact: widget.compact),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: CascaSpacing.space3,
                vertical: CascaSpacing.space4,
              ),
              children: [
                for (var i = 0; i < nav.sections.length; i++) ...[
                  if (i > 0) const SizedBox(height: CascaSpacing.space4),
                  _buildSection(nav.sections[i], first: i == 0),
                ],
              ],
            ),
          ),
          if (nav.preferences.isNotEmpty) _buildFooter(nav),
        ],
      ),
    );
  }

  Widget _buildSection(NavigationSection section, {required bool first}) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: widget.compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.stretch,
      children: [
        if (widget.compact && !first)
          Container(
            width: CascaSpacing.space6,
            height: 1,
            margin: const EdgeInsets.only(bottom: CascaSpacing.space2),
            color: colors.border,
          ),
        if (!widget.compact)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CascaSpacing.space3,
              0,
              CascaSpacing.space3,
              CascaSpacing.space1,
            ),
            child: Text(
              section.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
                fontSize: CascaFontSize.xs,
                fontWeight: CascaFontWeight.medium,
                letterSpacing: 0.72,
              ),
            ),
          ),
        for (var i = 0; i < section.items.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          _buildItem(section.items[i]),
        ],
      ],
    );
  }

  Widget _buildItem(NavigationItem item) {
    if (!item.hasChildren) return _buildLeaf(item);
    return widget.compact ? _buildCompactParent(item) : _buildParent(item);
  }

  Widget _buildLeaf(NavigationItem item) {
    final route = item.route!;
    return _SidebarTile(
      icon: item.icon,
      label: item.label,
      compact: widget.compact,
      active: isRouteActive(widget.location, route),
      tooltip: widget.compact ? item.label : null,
      onTap: () => _navigate(route),
    );
  }

  Widget _buildParent(NavigationItem item) {
    final expanded = _expanded.contains(item.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SidebarTile(
          icon: item.icon,
          label: item.label,
          compact: false,
          parentActive: _hasActiveChild(item),
          expanded: expanded,
          trailing: AnimatedRotation(
            turns: expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: CascaIcon(
              CascaIcons.chevronRight,
              size: 11,
              color: context.casca.textMuted,
            ),
          ),
          onTap: () => _toggle(item.id),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.ease,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: _submenuIndent,
                    top: _subGap,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: _treeGap),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < item.children!.length; i++) ...[
                          if (i > 0) const SizedBox(height: _subGap),
                          _buildSubItem(
                            item.children![i],
                            last: i == item.children!.length - 1,
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildSubItem(NavigationItem child, {required bool last}) {
    final route = child.route!;
    return CustomPaint(
      painter: _TreePainter(last: last, color: context.casca.border),
      child: _SidebarTile(
        icon: null,
        label: child.label,
        compact: false,
        active: isRouteActive(widget.location, route, exact: true),
        height: _subItemHeight,
        onTap: () => _navigate(route),
      ),
    );
  }

  Widget _buildCompactParent(NavigationItem item) {
    return CascaPopover(
      targetAnchor: Alignment.topRight,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(CascaSpacing.space2, 0),
      triggerBuilder: (context, handle) => _SidebarTile(
        icon: item.icon,
        label: item.label,
        compact: true,
        parentActive: _hasActiveChild(item),
        open: handle.isOpen,
        tooltip: handle.isOpen ? null : item.label,
        onTap: handle.toggle,
      ),
      panelBuilder: (context, close) => _Flyout(
        item: item,
        location: widget.location,
        onNavigate: (route) {
          close();
          _navigate(route);
        },
      ),
    );
  }

  Widget _buildFooter(NavigationState nav) {
    final colors = context.casca;
    final target = widget.isMobile
        ? AppRoutes.preferences
        : nav.preferences.first.route!;

    return Container(
      padding: EdgeInsets.fromLTRB(
        CascaSpacing.space3,
        CascaSpacing.space3,
        CascaSpacing.space3,
        CascaSpacing.space3 + widget.bottomInset,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Align(
        alignment: widget.compact ? Alignment.center : Alignment.centerLeft,
        heightFactor: 1,
        child: _SidebarTile(
          icon: CascaIcons.gear,
          label: 'Preferencias',
          compact: widget.compact,
          active: _preferencesActive,
          tooltip: widget.compact ? 'Preferencias' : null,
          onTap: () => _navigate(target),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Container(
      height: topbarHeight,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? CascaSpacing.space3 : CascaSpacing.space4,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: compact
          ? const Center(child: BrandMark())
          : const Align(alignment: Alignment.centerLeft, child: BrandLockup()),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.compact,
    required this.onTap,
    this.active = false,
    this.parentActive = false,
    this.expanded = false,
    this.open = false,
    this.trailing,
    this.tooltip,
    this.height = _itemHeight,
  });

  final String? icon;
  final String label;
  final bool compact;
  final VoidCallback onTap;
  final bool active;
  final bool parentActive;
  final bool expanded;
  final bool open;
  final Widget? trailing;
  final String? tooltip;
  final double height;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final active = widget.active;
    final raised = widget.expanded || widget.open;

    Color? background;
    if (active) {
      background = colors.text.withValues(alpha: _hovered ? 0.14 : 0.1);
    } else if (widget.compact && widget.open) {
      background = colors.text.withValues(alpha: 0.12);
    } else if (widget.compact && widget.parentActive) {
      background = colors.text.withValues(alpha: 0.08);
    } else if (_hovered || widget.open) {
      background = colors.surfaceHover;
    }

    final Color textColor;
    if (active || _hovered || raised || widget.parentActive) {
      textColor = colors.text;
    } else {
      textColor = colors.textSecondary;
    }

    final iconColor = textColor;
    final bold = active || widget.parentActive;
    final icon = widget.icon;
    final compact = widget.compact;

    Widget buildContent(Color textColor, Color iconColor) => compact
        ? Center(
            child: CascaIcon(
              icon!,
              size: _compactIconSize,
              color: iconColor,
              filled: active || widget.parentActive,
            ),
          )
        : Row(
            children: [
              if (icon != null) ...[
                SizedBox(
                  width: _expandedIconBox,
                  child: Center(
                    child: CascaIcon(
                      icon,
                      size: _expandedIconSize,
                      filled: active || widget.parentActive,
                      color: iconColor,
                    ),
                  ),
                ),
                const SizedBox(width: CascaSpacing.space3),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontSize: CascaFontSize.sm,
                    fontWeight: bold
                        ? CascaFontWeight.semibold
                        : CascaFontWeight.medium,
                  ),
                ),
              ),
              ?widget.trailing,
            ],
          );

    final colorDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    Widget tile = AnimatedContainer(
      duration: colorDuration,
      width: compact ? _compactItemSize : null,
      constraints: BoxConstraints(
        minHeight: compact ? _compactItemSize : widget.height,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? CascaSpacing.space2 : CascaSpacing.space3,
        vertical: CascaSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: CascaRadius.sm,
      ),
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: textColor),
        duration: colorDuration,
        builder: (context, animatedText, _) => TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: iconColor),
          duration: colorDuration,
          builder: (context, animatedIcon, _) => buildContent(
            animatedText ?? textColor,
            animatedIcon ?? iconColor,
          ),
        ),
      ),
    );

    tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: tile,
      ),
    );

    final tooltip = widget.tooltip;
    if (tooltip != null) {
      tile = CascaTooltip(
        message: tooltip,
        position: CascaTooltipPosition.right,
        child: tile,
      );
    }

    return Semantics(
      button: true,
      selected: active,
      label: widget.label,
      excludeSemantics: true,
      child: tile,
    );
  }
}

class _Flyout extends StatelessWidget {
  const _Flyout({
    required this.item,
    required this.location,
    required this.onNavigate,
  });

  final NavigationItem item;
  final String location;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minWidth: _flyoutMinWidth),
      padding: const EdgeInsets.all(CascaSpacing.space2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: CascaRadius.sm,
        border: Border.all(color: colors.border),
        boxShadow: CascaShadows.lg,
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CascaSpacing.space3,
                vertical: CascaSpacing.space2,
              ),
              child: Text(
                item.label.toUpperCase(),
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                  fontSize: CascaFontSize.xs,
                  fontWeight: CascaFontWeight.medium,
                  letterSpacing: 0.72,
                ),
              ),
            ),
            for (final child in item.children!)
              _FlyoutLink(
                item: child,
                active: isRouteActive(location, child.route!, exact: true),
                onTap: () => onNavigate(child.route!),
              ),
          ],
        ),
      ),
    );
  }
}

class _FlyoutLink extends StatefulWidget {
  const _FlyoutLink({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final NavigationItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_FlyoutLink> createState() => _FlyoutLinkState();
}

class _FlyoutLinkState extends State<_FlyoutLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final active = widget.active;
    final background = active
        ? colors.text.withValues(alpha: _hovered ? 0.14 : 0.1)
        : (_hovered ? colors.surfaceHover : null);
    final textColor = colors.text;
    final iconColor = active ? colors.text : colors.textSecondary;

    return Semantics(
      button: true,
      selected: active,
      label: widget.item.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: _subItemHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: CascaSpacing.space3,
              vertical: CascaSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: CascaRadius.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: CascaFontSize.md,
                  child: Center(
                    child: CascaIcon(
                      widget.item.icon,
                      size: _flyoutIconSize,
                      color: iconColor,
                      filled: active,
                    ),
                  ),
                ),
                const SizedBox(width: CascaSpacing.space3),
                Flexible(
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      fontSize: CascaFontSize.sm,
                      fontWeight: active
                          ? CascaFontWeight.semibold
                          : CascaFontWeight.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  const _TreePainter({required this.last, required this.color});

  final bool last;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const x = -_treeGap + 0.5;
    final middle = size.height / 2;

    canvas.drawLine(const Offset(x, -_subGap), Offset(x, middle), paint);
    canvas.drawLine(Offset(x, middle), Offset(0, middle), paint);
    if (!last) {
      canvas.drawLine(
        Offset(x, middle),
        Offset(x, size.height + _subGap),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TreePainter oldDelegate) {
    return oldDelegate.last != last || oldDelegate.color != color;
  }
}
