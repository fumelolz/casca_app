import 'dart:math';

import 'package:flutter/painting.dart';

const double _viewBox = 512;
const double _cornerRadius = 112;
const double _handleStroke = 27;
const double _eyeRadius = 13;

void drawTicketBagIcon(
  Canvas canvas,
  Offset origin,
  double size, {
  required Color ink,
  required Color paper,
}) {
  final black = Paint()..color = ink;
  final white = Paint()..color = paper;

  canvas
    ..save()
    ..translate(origin.dx, origin.dy)
    ..scale(size / _viewBox)
    ..drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, _viewBox, _viewBox),
        const Radius.circular(_cornerRadius),
      ),
      black,
    );

  final body = Path()
    ..arcTo(const Rect.fromLTWH(126, 180, 56, 56), pi, pi / 2, false)
    ..arcTo(const Rect.fromLTWH(330, 180, 56, 56), pi * 1.5, pi / 2, false)
    ..arcTo(const Rect.fromLTWH(266, 256, 120, 120), 0, pi / 2, false)
    ..arcTo(const Rect.fromLTWH(126, 256, 120, 120), pi / 2, pi / 2, false)
    ..close();
  final handle = Path()
    ..moveTo(205.5, 184)
    ..lineTo(205.5, 154)
    ..arcTo(const Rect.fromLTWH(205.5, 103.5, 101, 101), pi, pi, false)
    ..lineTo(306.5, 184);

  canvas
    ..drawPath(body, white)
    ..drawPath(
      handle,
      Paint()
        ..color = paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = _handleStroke,
    )
    ..drawCircle(const Offset(214, 222), _eyeRadius, black)
    ..drawCircle(const Offset(298, 222), _eyeRadius, black)
    ..restore();
}
