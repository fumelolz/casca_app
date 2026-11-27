import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:casca_app/app/theme/casca_colors.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/printing/escpos_encoder.dart';
import 'package:casca_app/core/printing/sale_ticket_layout.dart';
import 'package:casca_app/core/printing/ticket_logo.dart';
import 'package:casca_app/core/printing/ticket_printer_settings.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double _margin = 8;
const double _blockGap = 2;
const double _separatorSpace = 10;
const double _separatorThickness = 2;
const double _columnGap = 12;
const double _bottomSpace = 24;
const double _qrModule = 6;
const double _qrSpace = 16;
const double _logoSize = 56;
const double _logoGap = 12;
const double _logoSpace = 8;
const Color _ink = Color(0xFF000000);

typedef TicketEncoder = Future<Uint8List> Function(
  List<TicketBlock> blocks,
  TicketPaper paper,
);

typedef _Painted = void Function(Canvas canvas);

final ticketEncoderProvider = Provider<TicketEncoder>((ref) => encodeTicket);

Future<Uint8List> encodeTicket(
  List<TicketBlock> blocks,
  TicketPaper paper,
) async {
  final width = paper.dots;
  final contentWidth = width - _margin * 2;
  final painters = <TextPainter>[];
  final drawings = <_Painted>[];
  var y = _margin;

  TextPainter layout(
    String text,
    TicketTextStyle style, {
    double? maxWidth,
    TextAlign align = TextAlign.left,
  }) {
    final available = maxWidth ?? contentWidth;
    final painter = TextPainter(
      text: TextSpan(text: text, style: _textStyle(style)),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: available, maxWidth: available);
    painters.add(painter);
    return painter;
  }

  void draw(TextPainter painter, double x, double top) {
    drawings.add((canvas) => painter.paint(canvas, Offset(x, top)));
  }

  for (final block in blocks) {
    switch (block) {
      case TicketText(:final text, :final style, :final centered):
        final painter = layout(
          text,
          style,
          align: centered ? TextAlign.center : TextAlign.left,
        );
        draw(painter, _margin, y);
        y += painter.height + _blockGap;
      case TicketRow(:final label, :final value, :final style):
        final amount = TextPainter(
          text: TextSpan(text: value, style: _textStyle(style)),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: contentWidth * 0.7);
        painters.add(amount);
        final title = layout(
          label,
          style,
          maxWidth: contentWidth - amount.width - _columnGap,
        );
        draw(title, _margin, y);
        draw(amount, width - _margin - amount.width, y);
        y += max(title.height, amount.height) + _blockGap;
      case TicketLogo():
        final name = TextPainter(
          text: TextSpan(
            style: _textStyle(TicketTextStyle.brand),
            children: const [
              TextSpan(text: 'Casca '),
              TextSpan(
                text: 'Tiendas',
                style: TextStyle(fontWeight: CascaFontWeight.regular),
              ),
            ],
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: contentWidth - _logoSize - _logoGap);
        painters.add(name);
        final left = max(
          _margin,
          (width - _logoSize - _logoGap - name.width) / 2,
        );
        final top = y;
        drawings.add(
          (canvas) => drawTicketBagIcon(
            canvas,
            Offset(left, top),
            _logoSize,
            ink: _ink,
            paper: CascaColors.light.surface,
          ),
        );
        draw(
          name,
          left + _logoSize + _logoGap,
          top + (_logoSize - name.height) / 2,
        );
        y += _logoSize + _logoSpace;
      case TicketQr(:final modules):
        final left = ((width - modules.length * _qrModule) / 2).floorToDouble();
        final top = (y + _qrSpace).floorToDouble();
        drawings.add((canvas) => _drawModules(canvas, modules, left, top));
        y = top + modules.length * _qrModule + _qrSpace;
      case TicketSeparator():
        final line = y + _separatorSpace / 2;
        drawings.add(
          (canvas) => canvas.drawRect(
            Rect.fromLTWH(_margin, line, contentWidth, _separatorThickness),
            Paint()..color = _ink,
          ),
        );
        y += _separatorSpace;
    }
  }

  final height = (y + _bottomSpace).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawColor(CascaColors.light.surface, BlendMode.src);
  for (final drawing in drawings) {
    drawing(canvas);
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final pixels = await image.toByteData();
  picture.dispose();
  image.dispose();
  for (final painter in painters) {
    painter.dispose();
  }

  return encodeEscPosImage(pixels!.buffer.asUint8List(), width: width);
}

void _drawModules(
  Canvas canvas,
  List<String> modules,
  double left,
  double top,
) {
  final paint = Paint()
    ..color = _ink
    ..isAntiAlias = false;

  for (final (row, line) in modules.indexed) {
    for (var column = 0; column < line.length; column++) {
      if (line[column] != '#') continue;
      canvas.drawRect(
        Rect.fromLTWH(
          left + column * _qrModule,
          top + row * _qrModule,
          _qrModule,
          _qrModule,
        ),
        paint,
      );
    }
  }
}

TextStyle _textStyle(TicketTextStyle style) {
  final (size, weight) = switch (style) {
    TicketTextStyle.small => (20.0, CascaFontWeight.medium),
    TicketTextStyle.normal => (23.0, CascaFontWeight.medium),
    TicketTextStyle.bold => (27.0, CascaFontWeight.semibold),
    TicketTextStyle.brand => (32.0, CascaFontWeight.semibold),
  };

  return TextStyle(
    fontFamily: 'Poppins',
    fontSize: size,
    fontWeight: weight,
    color: _ink,
    height: 1.25,
  );
}
