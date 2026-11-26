import 'dart:math' as math;

const int maxPricesPerRequest = 500;
const int maxPriceListNameLength = 100;

typedef PriceChanges = Map<String, double?>;

double? effectivePrice(
  String sellableItemId,
  Map<String, double> saved,
  PriceChanges pending,
) {
  return pending.containsKey(sellableItemId)
      ? pending[sellableItemId]
      : saved[sellableItemId];
}

double roundPrice(double price) => (price * 100).round() / 100;

PriceChanges withPendingChange(
  PriceChanges pending,
  Map<String, double> saved,
  String sellableItemId,
  double? price,
) {
  final next = {...pending};
  final rounded = price == null ? null : roundPrice(price);
  if (rounded == saved[sellableItemId]) {
    next.remove(sellableItemId);
  } else {
    next[sellableItemId] = rounded;
  }
  return next;
}

List<PriceChanges> priceBatches(PriceChanges pending) {
  final entries = pending.entries.toList();
  return [
    for (var i = 0; i < entries.length; i += maxPricesPerRequest)
      Map.fromEntries(
        entries.sublist(i, math.min(i + maxPricesPerRequest, entries.length)),
      ),
  ];
}

List<Map<String, Object?>> toPriceRequests(PriceChanges changes) {
  return [
    for (final entry in changes.entries)
      {'sellableItemId': entry.key, 'price': entry.value},
  ];
}

Map<String, double> applyChanges(
  Map<String, double> saved,
  PriceChanges changes,
) {
  final next = {...saved};
  for (final entry in changes.entries) {
    final price = entry.value;
    if (price == null) {
      next.remove(entry.key);
    } else {
      next[entry.key] = price;
    }
  }
  return next;
}
