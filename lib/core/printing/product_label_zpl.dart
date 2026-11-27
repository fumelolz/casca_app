import 'package:casca_app/core/printing/product_label.dart';
import 'package:casca_app/core/printing/product_label_layout.dart';

String buildProductLabelZpl(
  ProductLabel label, {
  Set<LabelField> fields = const {...LabelField.values},
  LabelSize size = const LabelSize(),
  int copies = 1,
}) {
  final layout = layoutProductLabel(label, fields: fields, size: size);
  final elements = layout.elements.map(_elementZpl).join();

  return '^XA^CI28^MNY^MTD^PW${layout.width}^LL${layout.height}^LH0,0'
      '$elements'
      '^PQ${copies.clamp(1, maxLabelCopies)}^XZ';
}

String _elementZpl(LabelElement element) {
  final origin = '^FO${element.x},${element.y}';

  return switch (element) {
    LabelText(:final font, :final width, :final lines, :final text) =>
      '$origin^A0N,$font,$font^FB$width,$lines,0,C^FD$text^FS',
    LabelBarcode(:final moduleWidth, :final height, :final data) =>
      '$origin^BY$moduleWidth^BCN,$height,N,N,N,N^FD$data^FS',
  };
}
