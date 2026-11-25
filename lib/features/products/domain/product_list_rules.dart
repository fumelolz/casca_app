enum ProfitTone { positive, negative, neutral }

class ProfitMargin {
  const ProfitMargin({
    required this.amount,
    required this.percentage,
    required this.tone,
  });

  final double amount;
  final int? percentage;
  final ProfitTone tone;
}

ProfitMargin? profitMargin(
  double price,
  double averageCost, {
  bool allowZeroCost = false,
}) {
  final hasCost = averageCost > 0 || (allowZeroCost && averageCost == 0);
  if (!hasCost) return null;

  final amount = ((price - averageCost) * 100).round() / 100;
  return ProfitMargin(
    amount: amount,
    percentage: price > 0 ? (amount / price * 100).round() : null,
    tone: amount > 0
        ? ProfitTone.positive
        : amount < 0
        ? ProfitTone.negative
        : ProfitTone.neutral,
  );
}

enum StockStatus {
  out('Sin stock'),
  critical('Stock bajo crítico'),
  optimal('Óptimo'),
  moderate('Moderado'),
  low('Bajo'),
  ok('En stock');

  const StockStatus(this.label);

  final String label;
}

class StockLevel {
  const StockLevel(this.status, this.percentage);

  final StockStatus status;
  final int? percentage;
}

StockLevel stockLevel(double stock, double minimum, double? maximum) {
  if (stock <= 0) {
    final hasMaximum = maximum != null && maximum != 0;
    return StockLevel(StockStatus.out, hasMaximum ? 0 : null);
  }

  final raw = maximum != null && maximum > 0 ? stock / maximum * 100 : null;
  final percentage = raw?.round().clamp(0, 100);

  if (stock <= minimum) return StockLevel(StockStatus.critical, percentage);
  if (raw == null) return const StockLevel(StockStatus.ok, null);
  if (raw > 75) return StockLevel(StockStatus.optimal, percentage);
  if (raw >= 50) return StockLevel(StockStatus.moderate, percentage);
  return StockLevel(StockStatus.low, percentage);
}
