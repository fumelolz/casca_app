import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/layout/navigation_item.dart';
import 'package:casca_app/core/layout/navigation_provider.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double preferencesNavWidth = 240;

bool isPreferencesLocation(NavigationState nav, String location) {
  return nav.preferences.any(
    (item) => item.route != null && isRouteActive(location, item.route!),
  );
}

class PreferencesNav extends ConsumerWidget {
  const PreferencesNav({
    super.key,
    required this.location,
    required this.isMobile,
  });

  final String location;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final nav = ref.watch(navigationProvider);

    if (!isPreferencesLocation(nav, location)) return const SizedBox.shrink();

    final groupStyle = textTheme.bodySmall?.copyWith(
      color: colors.textMuted,
      fontSize: CascaFontSize.xs,
      fontWeight: CascaFontWeight.semibold,
    );

    if (isMobile) return const _BackBar();

    return Container(
      width: preferencesNavWidth,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: CascaSpacing.space3,
          vertical: CascaSpacing.space4,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: CascaSpacing.space3,
              right: CascaSpacing.space3,
              bottom: CascaSpacing.space2,
            ),
            child: Text(
              'PREFERENCIAS',
              style: groupStyle?.copyWith(letterSpacing: 0.72),
            ),
          ),
          for (final group in nav.preferenceGroups) ...[
            if (group.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CascaSpacing.space3,
                  CascaSpacing.space3,
                  CascaSpacing.space3,
                  CascaSpacing.space1,
                ),
                child: Text(group.label, style: groupStyle),
              ),
            for (final item in group.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _PreferenceLink(
                  item: item,
                  active: isRouteActive(location, item.route!),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PreferenceLink extends StatefulWidget {
  const _PreferenceLink({required this.item, required this.active});

  final NavigationItem item;
  final bool active;

  @override
  State<_PreferenceLink> createState() => _PreferenceLinkState();
}

class _PreferenceLinkState extends State<_PreferenceLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final active = widget.active;
    final badge = widget.item.badge;

    final background = active
        ? colors.text.withValues(alpha: 0.1)
        : (_hovered ? colors.surfaceHover : null);
    final textColor = active
        ? colors.text
        : (_hovered ? colors.text : colors.textSecondary);

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
          onTap: () => context.go(widget.item.route!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: CascaSpacing.space3,
              vertical: CascaSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: CascaRadius.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                if (badge != null && badge > 0) ...[
                  const SizedBox(width: CascaSpacing.space2),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: CascaSpacing.space1,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.warning,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onPrimary,
                        fontSize: CascaFontSize.xs,
                        fontWeight: CascaFontWeight.semibold,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar();

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Volver a preferencias',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.go(AppRoutes.preferences),
          child: Container(
            height: _height,
            padding: const EdgeInsets.symmetric(
              horizontal: CascaSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                CascaIcon(
                  CascaIcons.arrowLeft,
                  size: CascaFontSize.sm,
                  color: colors.info,
                ),
                const SizedBox(width: CascaSpacing.space2),
                Text(
                  'Preferencias',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.info,
                    fontSize: CascaFontSize.sm,
                    fontWeight: CascaFontWeight.semibold,
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
