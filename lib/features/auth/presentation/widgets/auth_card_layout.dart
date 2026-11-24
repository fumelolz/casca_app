import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_link.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class AuthCardLayout extends StatelessWidget {
  const AuthCardLayout({
    super.key,
    required this.child,
    this.showBackLink = false,
    this.overlay,
  });

  static const double _cardWidth = 450;
  static const double _cardPadding = 36;

  final Widget child;
  final bool showBackLink;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final overlay = this.overlay;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GlowPainter(colors.infoSoft)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: CascaSpacing.space4,
                  vertical: CascaSpacing.space6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Brand(),
                    const SizedBox(height: CascaSpacing.space6),
                    Container(
                      width: _cardWidth,
                      padding: const EdgeInsets.all(_cardPadding),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: CascaRadius.sm,
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.6),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F0F172A),
                            blurRadius: 50,
                            spreadRadius: -12,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          child,
                          if (showBackLink) ...[
                            const SizedBox(height: CascaSpacing.space5),
                            const _BackToLogin(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ?overlay,
        ],
      ),
    );
  }
}

class AuthStatusBadge extends StatelessWidget {
  const AuthStatusBadge({super.key, required this.icon});

  static const double _size = 56;

  final String icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.infoSoft),
      child: CascaIcon(icon, size: CascaFontSize.xl, color: colors.info),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.info,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: CascaIcon(
                CascaIcons.brandBag,
                size: 22,
                color: colors.onInfo,
              ),
            ),
            const SizedBox(width: CascaSpacing.space3),
            Flexible(
              child: Text(
                'Casca tiendas',
                style: textTheme.displaySmall?.copyWith(letterSpacing: -0.64),
              ),
            ),
          ],
        ),
        const SizedBox(height: CascaSpacing.space3),
        Text(
          'Punto de venta y gestión de tiendas',
          style: textTheme.bodySmall?.copyWith(letterSpacing: 0.24),
        ),
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(
      canvas,
      size,
      center: Offset(size.width / 2, -size.height * 0.1),
      radiusX: 960,
      radiusY: 480,
    );
    _paintGlow(
      canvas,
      size,
      center: Offset(size.width, size.height),
      radiusX: 480,
      radiusY: 320,
    );
  }

  void _paintGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radiusX,
    required double radiusY,
  }) {
    final scaleY = radiusY / radiusX;
    final shader = RadialGradient(
      colors: [color, color.withValues(alpha: 0)],
      stops: const [0, 0.7],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: radiusX));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, scaleY);
    canvas.drawRect(
      Rect.fromLTRB(
        -center.dx,
        -center.dy / scaleY,
        size.width - center.dx,
        (size.height - center.dy) / scaleY,
      ),
      Paint()..shader = shader,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) => oldDelegate.color != color;
}

class _BackToLogin extends StatelessWidget {
  const _BackToLogin();

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CascaIcon(
          CascaIcons.arrowLeft,
          size: CascaFontSize.sm,
          color: colors.info,
        ),
        const SizedBox(width: CascaSpacing.space2),
        CascaLink(
          label: 'Volver a iniciar sesión',
          onTap: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
