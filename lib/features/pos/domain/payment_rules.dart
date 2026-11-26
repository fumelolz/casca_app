import 'dart:math' as math;

const int _maxIntegerDigits = 9;
const int _maxDecimals = 2;
const List<int> _billsInCents = [2000, 5000, 10000, 20000, 50000, 100000];

enum PaymentMethod {
  cash(0),
  transfer(1),
  debitCard(3),
  creditCard(4);

  const PaymentMethod(this.code);

  final int code;
}

class PaymentLine {
  const PaymentLine({
    required this.method,
    required this.amountCents,
    this.receivedCents,
  });

  final PaymentMethod method;
  final int amountCents;
  final int? receivedCents;
}

class Payment {
  const Payment({required this.lines, this.receivedCents, this.changeCents});

  final List<PaymentLine> lines;
  final int? receivedCents;
  final int? changeCents;
}

int toCents(double amount) => (amount * 100 + 1e-7).round();

String centsToText(int cents) {
  final fraction = (cents % 100).toString().padLeft(_maxDecimals, '0');
  return '${cents ~/ 100}.$fraction';
}

int? parseMoneyToCents(String text) {
  if (!RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final decimals = parts.length > 1 ? parts[1] : '';
  return int.parse(parts.first) * 100 +
      int.parse(decimals.padRight(_maxDecimals, '0'));
}

String sanitizeMoneyText(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
  final dot = cleaned.indexOf('.');
  var integer = (dot == -1 ? cleaned : cleaned.substring(0, dot)).replaceFirst(
    RegExp(r'^0+(?=\d)'),
    '',
  );
  integer = integer.substring(0, math.min(integer.length, _maxIntegerDigits));
  if (dot == -1) return integer;

  final decimals = cleaned.substring(dot + 1).replaceAll('.', '');
  final limited = decimals.substring(
    0,
    math.min(decimals.length, _maxDecimals),
  );
  return '${integer.isEmpty ? '0' : integer}.$limited';
}

int? suggestedBillCents(int totalCents) {
  if (totalCents <= 0) return null;
  for (final bill in _billsInCents) {
    if (bill > totalCents) return bill;
  }
  final top = _billsInCents.last;
  return (totalCents ~/ top + 1) * top;
}

List<int> quickCashAmounts(int totalCents) {
  final bill = suggestedBillCents(totalCents);
  if (bill == null) return const [];
  return [totalCents, bill, bill * 2];
}

Payment? cashPayment(int totalCents, String receivedText) {
  final received = parseMoneyToCents(receivedText);
  if (totalCents <= 0 || received == null || received < totalCents) return null;

  return Payment(
    lines: [
      PaymentLine(
        method: PaymentMethod.cash,
        amountCents: totalCents,
        receivedCents: received,
      ),
    ],
    receivedCents: received,
    changeCents: received - totalCents,
  );
}

Payment singlePayment(PaymentMethod method, int totalCents) {
  return Payment(
    lines: [PaymentLine(method: method, amountCents: totalCents)],
  );
}

class SplitEvaluation {
  const SplitEvaluation({
    required this.shortfallCents,
    required this.changeCents,
    required this.exceedsTotal,
    this.payment,
  });

  final int shortfallCents;
  final int changeCents;
  final bool exceedsTotal;
  final Payment? payment;
}

SplitEvaluation evaluateSplit(
  int totalCents,
  Map<PaymentMethod, String> amounts,
) {
  int cents(PaymentMethod method) {
    return parseMoneyToCents(amounts[method] ?? '') ?? 0;
  }

  final cashReceived = cents(PaymentMethod.cash);
  final nonCash = [
    for (final method in PaymentMethod.values)
      if (method != PaymentMethod.cash && cents(method) > 0)
        PaymentLine(method: method, amountCents: cents(method)),
  ];
  final nonCashTotal = nonCash.fold(0, (sum, line) => sum + line.amountCents);
  final shortfall = math.max(0, totalCents - cashReceived - nonCashTotal);
  final exceeds = nonCashTotal > totalCents;
  final cashApplied = math.max(
    0,
    math.min(cashReceived, totalCents - nonCashTotal),
  );
  final change = exceeds ? 0 : cashReceived - cashApplied;
  final lines = [
    if (cashApplied > 0)
      PaymentLine(
        method: PaymentMethod.cash,
        amountCents: cashApplied,
        receivedCents: cashReceived,
      ),
    ...nonCash,
  ];
  final canCharge =
      totalCents > 0 && lines.isNotEmpty && shortfall == 0 && !exceeds;

  return SplitEvaluation(
    shortfallCents: shortfall,
    changeCents: change,
    exceedsTotal: exceeds,
    payment: canCharge
        ? Payment(
            lines: lines,
            receivedCents: cashReceived > 0 ? cashReceived : null,
            changeCents: cashReceived > 0 ? change : null,
          )
        : null,
  );
}
