import 'dart:math';

import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/home/data/models/dashboard_summary_model.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:material_ui/material_ui.dart';

const double _donutSize = 168;
const double _ringWidth = 22;
const double _segmentGap = 0.04;
const double _dotSize = 10;

class PaymentMethodsPanel extends StatelessWidget {
  const PaymentMethodsPanel({
    super.key,
    required this.payments,
    this.sideBySide = false,
  });

  final List<DashboardPayment> payments;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final palette = [
      colors.primary,
      colors.success,
      colors.warning,
      colors.info,
      colors.textMuted,
    ];
    final paid = payments.where((payment) => payment.total > 0).toList();
    final total = paid.fold(0.0, (sum, payment) => sum + payment.total);
    Color colorOf(int index) => palette[index % palette.length];

    if (paid.isEmpty) {
      return CascaCard(
        title: 'Cómo te pagaron',
        child: Text(
          'Aún no hay ventas registradas hoy.',
          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
      );
    }

    final donut = SizedBox(
      width: _donutSize,
      height: _donutSize,
      child: CustomPaint(
        painter: _DonutPainter(
          shares: [for (final payment in paid) payment.total / total],
          colors: [
            for (var index = 0; index < paid.length; index++) colorOf(index),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_ringWidth + CascaSpacing.space2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Cobrado', style: textTheme.bodySmall),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMoney(total),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: CascaFontWeight.semibold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CascaSpacing.space3,
      children: [
        for (final (index, payment) in paid.indexed)
          Row(
            spacing: CascaSpacing.space2,
            children: [
              Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: colorOf(index),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  '${payment.method} · '
                  '${(payment.total / total * 100).round()} %',
                  style: textTheme.bodyMedium,
                ),
              ),
              Text(
                formatMoney(payment.total),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: CascaFontWeight.semibold,
                ),
              ),
            ],
          ),
      ],
    );

    return CascaCard(
      title: 'Cómo te pagaron',
      child: sideBySide
          ? Row(
              spacing: CascaSpacing.space5,
              children: [
                donut,
                Expanded(child: legend),
              ],
            )
          : Column(spacing: CascaSpacing.space4, children: [donut, legend]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.shares, required this.colors});

  final List<double> shares;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(_ringWidth / 2);
    final gap = shares.length > 1 ? _segmentGap : 0.0;
    var start = -pi / 2;

    for (final (index, share) in shares.indexed) {
      final sweep = share * pi * 2;
      canvas.drawArc(
        bounds,
        start + gap / 2,
        max(0.01, sweep - gap),
        false,
        Paint()
          ..color = colors[index]
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}
