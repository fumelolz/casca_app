import 'package:casca_app/features/cash_registers/domain/shift_rules.dart';

enum CountMethod {
  cash(0, 'Efectivo'),
  creditCard(4, 'Tarjeta de Crédito'),
  debitCard(3, 'Tarjeta de Débito'),
  transfer(1, 'Transferencia');

  const CountMethod(this.code, this.label);

  final int code;
  final String label;
}

class ShiftCount {
  const ShiftCount({required this.expected, required this.counted});

  final Map<CountMethod, double> expected;
  final Map<CountMethod, double?> counted;

  double expectedOf(CountMethod method) => expected[method] ?? 0;

  bool isRequired(CountMethod method) {
    return method == CountMethod.cash || expectedOf(method) > 0;
  }

  double? differenceOf(CountMethod method) {
    final amount = counted[method];
    if (amount == null) return null;
    return roundMoney(amount - expectedOf(method));
  }

  bool get complete {
    return CountMethod.values.every(
      (method) => !isRequired(method) || counted[method] != null,
    );
  }

  bool get hasDifference {
    return CountMethod.values.any((method) => (differenceOf(method) ?? 0) != 0);
  }

  double get countedCash => counted[CountMethod.cash] ?? 0;

  double get countedTotal {
    return roundMoney(
      CountMethod.values.fold(0, (sum, method) {
        return sum + (counted[method] ?? 0);
      }),
    );
  }

  double get expectedTotal {
    return roundMoney(
      CountMethod.values.fold(0, (sum, method) => sum + expectedOf(method)),
    );
  }

  Map<int, double> get paymentCounts {
    return {
      for (final method in CountMethod.values)
        if (method != CountMethod.cash &&
            (counted[method] != null || expectedOf(method) > 0))
          method.code: counted[method] ?? 0,
    };
  }
}

bool isValidWithdrawal(double countedCash, double? withdrawn) {
  return withdrawn != null &&
      withdrawn >= 0 &&
      roundMoney(countedCash - withdrawn) >= 0;
}

bool openingNotesRequired(double? suggested, double? amount) {
  return suggested != null &&
      amount != null &&
      roundMoney(amount) != roundMoney(suggested);
}
