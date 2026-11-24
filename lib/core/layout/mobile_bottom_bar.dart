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
const double mobileBottomBarHump = 28;
const double _borderWidth = 1;
const double _curveHeight = 12;
const double _curveWidth = 132;
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

    final posIndex = tabs.indexWhere((tab) => tab.id == posTabId);
    final hasHump = posIndex >= 0;
    final hump = hasHump ? mobileBottomBarHump : 0.0;

    return SizedBox(
      height: hump + mobileBottomBarExtent(bottomInset),
      child: CustomPaint(
        painter: _BarPainter(
          fill: colors.surface,
          border: colors.border,
          hump: hump,
          humpCenter: hasHump ? (posIndex + 0.5) / tabs.length : null,
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
                    lifted: tab.id == posTabId,
                    hump: hump,
                    onTap: () {
                      controller.closeMobile();
                      context.go(tab.route!);
                    },
                  ),
                ),
            ],
          ),
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
    required this.lifted,
    required this.hump,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final bool lifted;
  final double hump;
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
                    padding: EdgeInsets.only(top: widget.hump),
                    child: content,
                  ),
                  ScaleTransition(
                    scale: _scale,
                    child: _Circle(icon: widget.icon, active: widget.active),
                  ),
                ],
              )
            : Padding(
                padding: EdgeInsets.only(top: widget.hump),
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

class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.fill,
    required this.border,
    required this.hump,
    required this.humpCenter,
  });

  final Color fill;
  final Color border;
  final double hump;
  final double? humpCenter;

  Path _topLine(Size size) {
    final path = Path()..moveTo(0, hump);
    final fraction = humpCenter;

    if (fraction != null) {
      final center = size.width * fraction;
      final half = _curveWidth / 2;
      final peak = hump - _curveHeight;
      path
        ..lineTo(center - half, hump)
        ..cubicTo(
          center - half * 0.55,
          hump,
          center - half * 0.45,
          peak,
          center,
          peak,
        )
        ..cubicTo(
          center + half * 0.45,
          peak,
          center + half * 0.55,
          hump,
          center + half,
          hump,
        );
    }

    return path..lineTo(size.width, hump);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final top = _topLine(size);
    final shape = Path.from(top)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      top,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );
  }

  @override
  bool hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_BarPainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.border != border ||
        oldDelegate.hump != hump ||
        oldDelegate.humpCenter != humpCenter;
  }
}
