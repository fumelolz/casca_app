final RegExp _skuWithMisreadSeparator = RegExp(
  "^(PRD|VAR)[-'´`?¿_]([0-9A-F]{6})\$",
  caseSensitive: false,
);

String normalizeScannedCode(String raw) {
  final code = raw.trim();
  final match = _skuWithMisreadSeparator.firstMatch(code);
  if (match == null) return code;
  return '${match.group(1)!.toUpperCase()}-${match.group(2)!.toUpperCase()}';
}
