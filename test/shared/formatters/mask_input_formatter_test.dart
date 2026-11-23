import 'package:casca_app/shared/formatters/mask_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

String _type(MaskInputFormatter formatter, String text) {
  return formatter
      .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
      .text;
}

void main() {
  group('teléfono', () {
    const phone = MaskInputFormatter.phone;

    test('vacío se queda vacío', () {
      expect(_type(phone, ''), '');
    });

    test('aplica la máscara a medida que se escribe', () {
      expect(_type(phone, '5'), '(5');
      expect(_type(phone, '555'), '(555');
      expect(_type(phone, '5551'), '(555) 1');
      expect(_type(phone, '5551234'), '(555) 123-4');
      expect(_type(phone, '5551234567'), '(555) 123-4567');
    });

    test('ignora letras y símbolos', () {
      expect(_type(phone, 'a5b5-5'), '(555');
    });

    test('no excede los 10 dígitos', () {
      expect(_type(phone, '555123456789'), '(555) 123-4567');
    });

    test('reaplica la máscara si se pega un número con formato', () {
      expect(_type(phone, '(555) 123-4567'), '(555) 123-4567');
    });

    test('borrar el último dígito no deja literales colgando', () {
      expect(_type(phone, '(555) '), '(555');
    });

    test('el cursor queda al final', () {
      final value = phone.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '5551'),
      );

      expect(value.selection.baseOffset, value.text.length);
    });
  });

  test('digitsOnly quita todo lo que no es dígito', () {
    expect(MaskInputFormatter.digitsOnly('(555) 123-4567'), '5551234567');
  });
}
