import 'package:material_ui/material_ui.dart';

abstract final class CascaShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1A0F172A), blurRadius: 24, offset: Offset(0, 12)),
  ];
}
