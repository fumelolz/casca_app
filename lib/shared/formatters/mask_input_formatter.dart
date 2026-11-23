import 'package:flutter/services.dart';

class MaskInputFormatter extends TextInputFormatter {
  const MaskInputFormatter(this.mask);

  static const String digitSlot = '0';

  static const MaskInputFormatter phone = MaskInputFormatter('(000) 000-0000');

  final String mask;

  static String digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  int get _capacity => digitSlot.allMatches(mask).length;

  String _apply(String digits) {
    final buffer = StringBuffer();
    var used = 0;

    for (final char in mask.split('')) {
      if (used == digits.length) break;
      if (char == digitSlot) {
        buffer.write(digits[used]);
        used++;
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = digitsOnly(newValue.text);
    if (digits.length > _capacity) digits = digits.substring(0, _capacity);

    final text = _apply(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
