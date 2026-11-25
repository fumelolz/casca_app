import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/layout/navigation_item.dart';
import 'package:casca_app/core/layout/navigation_provider.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double mobileBottomBarHeight = 64;
const double _borderWidth = 1;
const double _iconSize = 24;
const double _popScale = 1.22;
const Duration _popDuration = Duration(milliseconds: 320);
const Duration _colorDuration = Duration(milliseconds: 200);

double mobileBottomBarExtent(double bottomInset) {
  return mobileBottomBarHeight + _borderWidth + bottomInset;
}

class MobileBottomBar extends ConsumerWidget {
  const MobileBottomBar({
    super.key,
    required this.location,
    required this.bottomInset,
  });

  final String location;
  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final tabs = ref.watch(navigationProvider.select((nav) => nav.mobileTabs));
    final controller = ref.read(sidebarProvider.notifier);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: _borderWidth, bottom: bottomInset),
        child: Row(
          children: [
            for (final tab in tabs)
              Expanded(
                child: _BarItem(
                  icon: tab.icon,
                  label: tab.label,
                  active: isItemActive(location, tab),
                  onTap: () {
                    controller.closeMobile();
                    context.go(tab.route!);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatefulWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_BarItem> createState() => _BarItemState();
}

class _BarItemState extends State<_BarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: _popDuration,
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: _popScale,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: _popScale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 60,
    ),
  ]).animate(_pop);

  @override
  void didUpdateWidget(_BarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active &&
        widget.active &&
        !MediaQuery.disableAnimationsOf(context)) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final target = widget.active ? colors.text : colors.textSecondary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: target),
      duration: reduceMotion ? Duration.zero : _colorDuration,
      builder: (context, animated, _) {
        final color = animated ?? target;

        return Semantics(
          button: true,
          selected: widget.active,
          label: widget.label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: SizedBox(
              height: mobileBottomBarHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: CascaIcon(
                      widget.icon,
                      size: _iconSize,
                      color: color,
                      filled: widget.active,
                    ),
                  ),
                  const SizedBox(height: CascaSpacing.space1),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: color,
                      fontSize: CascaFontSize.xs,
                      fontWeight: widget.active
                          ? CascaFontWeight.semibold
                          : CascaFontWeight.medium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
