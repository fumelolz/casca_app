import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/layout/navigation_item.dart';
import 'package:casca_app/core/layout/navigation_items.dart';
import 'package:casca_app/core/layout/navigation_provider.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double mobileBottomBarHeight = 64;
const double mobileBottomBarLift = 28;
const double _borderWidth = 1;
const double _iconSize = 24;
const double _circleSize = 56;
const double _circleRing = 4;
const double _circleIconSize = 24;
const double _popScale = 1.22;
const double _haloRingAlpha = 0.3;
const double _haloGlowAlpha = 0.4;
const double _haloBlur = 14;
const double _haloSpread = 1.5;
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

    final hasPos = tabs.any((tab) => tab.id == posTabId);
    final lift = hasPos ? mobileBottomBarLift : 0.0;

    return SizedBox(
      height: lift + mobileBottomBarExtent(bottomInset),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: lift,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: _borderWidth, bottom: bottomInset),
            child: Row(
              children: [
                for (final tab in tabs)
                  Expanded(
                    child: _BarItem(
                      icon: tab.icon,
                      label: tab.label,
                      active: isItemActive(location, tab),
                      lifted: tab.id == posTabId,
                      lift: lift,
                      onTap: () {
                        controller.closeMobile();
                        context.go(tab.route!);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatefulWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.lifted,
    required this.lift,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final bool lifted;
  final double lift;
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

        final content = SizedBox(
          height: mobileBottomBarHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _iconSize,
                  child: widget.lifted
                      ? null
                      : ScaleTransition(
                          scale: _scale,
                          child: CascaIcon(
                            widget.icon,
                            size: _iconSize,
                            color: color,
                            filled: widget.active,
                          ),
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
        );

        final Widget item = widget.lifted
            ? Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: widget.lift),
                    child: content,
                  ),
                  ScaleTransition(
                    scale: _scale,
                    child: _Circle(icon: widget.icon, active: widget.active),
                  ),
                ],
              )
            : Padding(
                padding: EdgeInsets.only(top: widget.lift),
                child: content,
              );

        return Semantics(
          button: true,
          selected: widget.active,
          label: widget.label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: item,
          ),
        );
      },
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.icon, required this.active});

  final String icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final haloRing = Color.alphaBlend(
      colors.primary.withValues(alpha: _haloRingAlpha),
      colors.surface,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(end: active ? 1.0 : 0.0),
      duration: reduceMotion ? Duration.zero : _colorDuration,
      builder: (context, t, _) {
        return Container(
          key: const Key('vender-circle'),
          width: _circleSize,
          height: _circleSize,
          padding: const EdgeInsets.all(_circleRing),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(colors.surface, haloRing, t),
            boxShadow: [
              ...CascaShadows.md,
              BoxShadow(
                color: colors.primary.withValues(alpha: _haloGlowAlpha * t),
                blurRadius: _haloBlur,
                spreadRadius: _haloSpread * t,
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary,
            ),
            child: Center(
              child: CascaIcon(
                icon,
                size: _circleIconSize,
                color: colors.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
