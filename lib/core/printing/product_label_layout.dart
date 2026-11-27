import 'dart:math';

import 'package:casca_app/core/printing/product_label.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';

const int _dotsPerMm = 8;
const int _margin = 16;
const int _verticalMargin = 8;
const int _nameCharsPerLine = 24;
const int _nameFont = 30;
const int _skuFont = 24;
const int _priceFont = 34;
const int _codeFont = 22;
const int _lineGap = 4;
const int _minBarcodeHeight = 28;
const int _maxBarcodeHeight = 70;
const int _barcodeGap = 4;

sealed class LabelElement {
  const LabelElement({required this.x, required this.y, required this.width});

  final int x;
  final int y;
  final int width;
}

class LabelText extends LabelElement {
  const LabelText({
    required super.x,
    required super.y,
    required super.width,
    required this.text,
    required this.font,
    this.lines = 1,
  });

  final String text;
  final int font;
  final int lines;
}

class LabelBarcode extends LabelElement {
  const LabelBarcode({
    required super.x,
    required super.y,
    required super.width,
    required this.height,
    required this.moduleWidth,
    required this.data,
    required this.text,
  });

  final int height;
  final int moduleWidth;
  final String data;
  final String text;
}

class ProductLabelLayout {
  const ProductLabelLayout({
    required this.width,
    required this.height,
    required this.elements,
  });

  final int width;
  final int height;
  final List<LabelElement> elements;
}

ProductLabelLayout layoutProductLabel(
  ProductLabel label, {
  Set<LabelField> fields = const {...LabelField.values},
  LabelSize size = const LabelSize(),
}) {
  final width = size.widthMm * _dotsPerMm;
  final height = size.heightMm * _dotsPerMm;
  final contentWidth = width - _margin * 2;
  final usesSkuAsBarcode = (label.barcode ?? '').trim().isEmpty;
  final barcode = fields.contains(LabelField.barcode)
      ? _Barcode.from(usesSkuAsBarcode ? label.sku : label.barcode!)
      : null;
  final skuAlreadyPrinted = barcode != null && usesSkuAsBarcode;

  final elements = <LabelElement>[];
  var y = _verticalMargin;

  void centeredText(String text, int font, {int lines = 1}) {
    elements.add(
      LabelText(
        x: _margin,
        y: y,
        width: contentWidth,
        text: text,
        font: font,
        lines: lines,
      ),
    );
  }

  final name = _sanitize(label.name);
  if (fields.contains(LabelField.name) && name.isNotEmpty) {
    final lines = name.length > _nameCharsPerLine ? 2 : 1;
    centeredText(name, _nameFont, lines: lines);
    y += lines * (_nameFont + _lineGap);
  }

  final sku = _sanitize(label.sku);
  if (fields.contains(LabelField.sku) && !skuAlreadyPrinted && sku.isNotEmpty) {
    centeredText(sku, _skuFont);
    y += _skuFont + _lineGap;
  }

  if (fields.contains(LabelField.price)) {
    centeredText(formatMoney(label.price), _priceFont);
    y += _priceFont + _lineGap;
  }

  if (barcode != null) {
    final showCode = !usesSkuAsBarcode || fields.contains(LabelField.sku);
    final codeSpace = showCode ? _codeFont + _barcodeGap : 0;
    final available = height - _verticalMargin - y - codeSpace - _barcodeGap;
    final barHeight = available.clamp(_minBarcodeHeight, _maxBarcodeHeight);
    final moduleWidth = barcode.modules * 2 <= contentWidth ? 2 : 1;
    final barWidth = barcode.modules * moduleWidth;

    elements.add(
      LabelBarcode(
        x: _margin + max(0, (contentWidth - barWidth) ~/ 2),
        y: y,
        width: barWidth,
        height: barHeight,
        moduleWidth: moduleWidth,
        data: barcode.data,
        text: barcode.text,
      ),
    );
    if (showCode) {
      y += barHeight + _barcodeGap;
      centeredText(barcode.text, _codeFont);
    }
  }

  return ProductLabelLayout(width: width, height: height, elements: elements);
}

String _sanitize(String value) {
  return value.replaceAll(RegExp(r'[\^~\r\n]'), ' ').trim();
}

class _Barcode {
  const _Barcode(this.data, this.text, this.modules);

  static _Barcode? from(String value) {
    final text = value.replaceAll(RegExp(r'[^ -~]|[\^~]'), '').trim();
    if (text.isEmpty) return null;

    final onlyDigits = RegExp(r'^\d+$').hasMatch(text);
    final String data;
    final int symbols;

    if (onlyDigits && text.length.isEven) {
      data = '>;$text';
      symbols = text.length ~/ 2;
    } else if (onlyDigits && text.length >= 3) {
      final last = text.length - 1;
      data = '>;${text.substring(0, last)}>6${text.substring(last)}';
      symbols = last ~/ 2 + 2;
    } else {
      data = '>:${text.replaceAll('>', '>0')}';
      symbols = text.length;
    }

    return _Barcode(data, text, 11 * (symbols + 2) + 13);
  }

  final String data;
  final String text;
  final int modules;
}
