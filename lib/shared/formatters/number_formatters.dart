String formatMoney(double amount) {
  final sign = amount < 0 ? '-' : '';
  final parts = amount.abs().toStringAsFixed(2).split('.');
  return '$sign\$${_groupThousands(parts.first)}.${parts.last}';
}

String formatQuantity(double quantity) {
  final sign = quantity < 0 ? '-' : '';
  final parts = quantity.abs().toStringAsFixed(3).split('.');
  final decimals = parts.last.replaceFirst(RegExp(r'0+$'), '');
  final integer = _groupThousands(parts.first);
  return decimals.isEmpty ? '$sign$integer' : '$sign$integer.$decimals';
}

String _groupThousands(String digits) {
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}
