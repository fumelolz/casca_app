import 'package:casca_app/features/auth/domain/password_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('una contraseña vacía no cumple ningún requisito', () {
    expect(checkPassword('').every((check) => check.met), isFalse);
    expect(checkPassword('').where((check) => check.met), isEmpty);
  });

  test('marca cada requisito por separado', () {
    final met = {
      for (final check in checkPassword('abcdefgh')) check.label: check.met,
    };

    expect(met['Al menos 8 caracteres'], isTrue);
    expect(met['Una letra minúscula'], isTrue);
    expect(met['Una letra mayúscula'], isFalse);
    expect(met['Un número'], isFalse);
    expect(met['Un carácter especial'], isFalse);
  });

  test('acepta una contraseña que cumple todo', () {
    expect(isPasswordValid('Abcdef1!'), isTrue);
  });

  test('rechaza si falta un requisito o excede 100 caracteres', () {
    expect(isPasswordValid('Abcdef1x'), isFalse);
    expect(isPasswordValid('Abcdef1!${'a' * 100}'), isFalse);
  });
}
