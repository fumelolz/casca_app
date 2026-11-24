import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

class CascaOverlayLoader extends StatefulWidget {
  const CascaOverlayLoader({
    super.key,
    required this.visible,
    this.heading = 'Cargando',
    this.message,
    this.icon = CascaIcons.brandBag,
  });

  final bool visible;
  final String heading;
  final String? message;
  final String icon;

  @override
  State<CascaOverlayLoader> createState() => _CascaOverlayLoaderState();
}

class _CascaOverlayLoaderState extends State<CascaOverlayLoader>
    with TickerProviderStateMixin {
  static const _fadeDuration = Duration(milliseconds: 250);
  static const _loopSeconds = 36;

  late final AnimationController _fade;
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: _fadeDuration,
      value: widget.visible ? 1 : 0,
    );
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _loopSeconds),
    );
    _fade.addStatusListener(_onFadeStatus);
    if (widget.visible) _loop.repeat();
  }

  @override
  void didUpdateWidget(CascaOverlayLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _loop.repeat();
      _fade.forward();
    } else {
      _fade.reverse();
    }
  }

  void _onFadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) _loop.stop();
  }

  @override
  void dispose() {
    _fade.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final fade = CurvedAnimation(parent: _fade, curve: Curves.ease);

    return AnimatedBuilder(
      animation: fade,
      builder: (context, _) {
        if (_fade.isDismissed && !widget.visible) {
          return const SizedBox.shrink();
        }
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: !widget.visible,
            child: Opacity(
              opacity: reduceMotion ? (widget.visible ? 1 : 0) : fade.value,
              child: _Backdrop(
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: [widget.heading, ?widget.message].join('. '),
                  child: ExcludeSemantics(
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        reduceMotion ? 0 : 8 * (1 - fade.value),
                      ),
                      child: Transform.scale(
                        scale: reduceMotion ? 1 : 0.98 + 0.02 * fade.value,
                        child: _Content(
                          loop: _loop,
                          reduceMotion: reduceMotion,
                          heading: widget.heading,
                          message: widget.message,
                          icon: widget.icon,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: ColoredBox(
          color: colors.background.withValues(alpha: 0.82),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(CascaSpacing.space6),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.loop,
    required this.reduceMotion,
    required this.heading,
    required this.message,
    required this.icon,
  });

  final Animation<double> loop;
  final bool reduceMotion;
  final String heading;
  final String? message;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final text = message;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Emblem(loop: loop, reduceMotion: reduceMotion, icon: icon),
        const SizedBox(height: CascaSpacing.space3),
        Text(
          heading,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(color: colors.text),
        ),
        if (text != null) ...[
          const SizedBox(height: CascaSpacing.space3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
        const SizedBox(height: CascaSpacing.space5),
        _ProgressBar(loop: loop, reduceMotion: reduceMotion),
      ],
    );
  }
}

double _cycle(Animation<double> loop, double periodSeconds) {
  final seconds = loop.value * _CascaOverlayLoaderState._loopSeconds;
  return (seconds / periodSeconds) % 1;
}

class _Emblem extends StatelessWidget {
  const _Emblem({
    required this.loop,
    required this.reduceMotion,
    required this.icon,
  });

  static const _size = 96.0;
  static const _ringInset = 4.0;
  static const _ringStroke = 3.0;
  static const _iconCircle = 56.0;
  static const _iconSize = CascaFontSize.xl;
  static const _spin = Cubic(0.5, 0.1, 0.5, 0.9);

  final Animation<double> loop;
  final bool reduceMotion;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return SizedBox.square(
      dimension: _size,
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          final pulse = reduceMotion
              ? 0.0
              : Curves.easeOut.transform(_cycle(loop, 1.8));
          final spin = reduceMotion ? 0.0 : _spin.transform(_cycle(loop, 1));
          final float = reduceMotion
              ? 0.0
              : -3 * (0.5 - 0.5 * math.cos(2 * math.pi * _cycle(loop, 2.4)));

          return Stack(
            alignment: Alignment.center,
            children: [
              if (!reduceMotion)
                Opacity(
                  opacity: 0.9 * (1 - pulse),
                  child: Transform.scale(
                    scale: 0.7 + 0.45 * pulse,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primarySoft,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(_ringInset),
                child: Transform.rotate(
                  angle: 2 * math.pi * spin,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _RingPainter(
                      color: colors.primary,
                      strokeWidth: _ringStroke,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, float),
                child: Container(
                  width: _iconCircle,
                  height: _iconCircle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    boxShadow: CascaShadows.md,
                  ),
                  child: CascaIcon(
                    icon,
                    size: _iconSize,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    canvas.drawArc(rect, -3 * math.pi / 4, math.pi, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.loop, required this.reduceMotion});

  static const _width = 192.0;
  static const _height = 4.0;
  static const _segment = 0.4;

  final Animation<double> loop;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_height),
      child: SizedBox(
        width: _width,
        height: _height,
        child: ColoredBox(
          color: colors.border,
          child: reduceMotion
              ? Opacity(opacity: 0.5, child: ColoredBox(color: colors.primary))
              : AnimatedBuilder(
                  animation: loop,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(_cycle(loop, 1.2));
                    final segmentWidth = _width * _segment;
                    final dx =
                        -segmentWidth + t * (_width * 1.1 + segmentWidth);

                    return Stack(
                      children: [
                        Positioned(
                          left: dx,
                          width: segmentWidth,
                          top: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(_height),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
