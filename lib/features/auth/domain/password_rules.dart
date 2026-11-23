class PasswordCheck {
  const PasswordCheck(this.label, this.shortLabel, {required this.met});

  final String label;
  final String shortLabel;
  final bool met;
}

List<PasswordCheck> checkPassword(String password) {
  return [
    PasswordCheck(
      'Al menos 8 caracteres',
      '8 caracteres',
      met: password.length >= 8,
    ),
    PasswordCheck(
      'Una letra mayúscula',
      'mayúscula',
      met: RegExp('[A-Z]').hasMatch(password),
    ),
    PasswordCheck(
      'Una letra minúscula',
      'minúscula',
      met: RegExp('[a-z]').hasMatch(password),
    ),
    PasswordCheck(
      'Un número',
      'número',
      met: RegExp('[0-9]').hasMatch(password),
    ),
    PasswordCheck(
      'Un carácter especial',
      'carácter especial',
      met: RegExp('[^a-zA-Z0-9]').hasMatch(password),
    ),
  ];
}

bool isPasswordValid(String password) {
  return password.length <= 100 && checkPassword(password).every((c) => c.met);
}
