import 'package:casca_app/app/theme/casca_colors.dart';
import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/printing/product_label_layout.dart';
import 'package:casca_app/features/products/domain/barcode_preview_rules.dart';
import 'package:material_ui/material_ui.dart';

const double _maxPreviewWidth = 320;
const double _maxPreviewHeight = 240;

class ProductLabelPreview extends StatelessWidget {
  const ProductLabelPreview({super.key, required this.layout});

  final ProductLabelLayout layout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _maxPreviewWidth,
          maxHeight: _maxPreviewHeight,
        ),
        child: AspectRatio(
          aspectRatio: layout.width / layout.height,
          child: Container(
            foregroundDecoration: BoxDecoration(
              borderRadius: CascaRadius.md,
              border: Border.all(color: context.casca.border),
            ),
            decoration: BoxDecoration(
              color: CascaColors.light.surface,
              borderRadius: CascaRadius.md,
            ),
            clipBehavior: Clip.antiAlias,
            child: FittedBox(
              child: SizedBox(
                width: layout.width.toDouble(),
                height: layout.height.toDouble(),
                child: Stack(
                  children: [
                    for (final element in layout.elements)
                      Positioned(
                        left: element.x.toDouble(),
                        top: element.y.toDouble(),
                        width: element.width.toDouble(),
                        child: switch (element) {
                          LabelText() => _PreviewText(element),
                          LabelBarcode() => _PreviewBarcode(element),
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewText extends StatelessWidget {
  const _PreviewText(this.element);

  final LabelText element;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      element.text,
      maxLines: element.lines,
      overflow: element.lines > 1 ? TextOverflow.ellipsis : null,
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: CascaColors.light.text,
        fontSize: element.font.toDouble(),
        height: 1,
      ),
    );

    return SizedBox(
      height: (element.font * element.lines).toDouble(),
      child: element.lines > 1
          ? text
          : FittedBox(fit: BoxFit.scaleDown, child: text),
    );
  }
}

class _PreviewBarcode extends StatelessWidget {
  const _PreviewBarcode(this.element);

  final LabelBarcode element;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(element.width.toDouble(), element.height.toDouble()),
      painter: _BarsPainter(element.text, CascaColors.light.text),
    );
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter(this.code, this.color);

  final String code;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final preview = buildBarcodePreview(code);
    final unit = size.width / preview.totalWidth;
    final paint = Paint()..color = color;

    for (final bar in preview.bars) {
      canvas.drawRect(
        Rect.fromLTWH(bar.x * unit, 0, bar.width * unit, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) {
    return old.code != code || old.color != color;
  }
}
