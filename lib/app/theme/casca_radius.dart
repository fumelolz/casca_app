import 'package:material_ui/material_ui.dart';

abstract final class CascaRadius {
  static const double smValue = 6;
  static const double mdValue = 10;
  static const double lgValue = 14;
  static const double xlValue = 18;

  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlValue));
}
