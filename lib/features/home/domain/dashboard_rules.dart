import 'package:casca_app/features/home/data/models/dashboard_summary_model.dart';

enum DashboardBlock {
  salesToday('sales-today'),
  ordersToday('orders-today', metric: true),
  averageTicket('average-ticket', metric: true),
  profitToday('profit-today', metric: true),
  paymentMethods('payment-methods'),
  topProducts('top-products'),
  lowStock('low-stock');

  const DashboardBlock(this.key, {this.metric = false});

  final String key;
  final bool metric;
}

typedef DashboardWidgetSetting = ({String key, bool enabled, int order});

List<DashboardBlock> visibleBlocks(List<DashboardWidgetSetting> saved) {
  if (saved.isEmpty) return DashboardBlock.values;

  final known = {for (final block in DashboardBlock.values) block.key: block};
  final ordered = [...saved]..sort((a, b) => a.order.compareTo(b.order));
  final seen = <DashboardBlock>{};
  final visible = <DashboardBlock>[];

  for (final setting in ordered) {
    final block = known[setting.key];
    if (block != null && seen.add(block) && setting.enabled) {
      visible.add(block);
    }
  }

  return [
    ...visible,
    ...DashboardBlock.values.where((block) => !seen.contains(block)),
  ];
}

List<List<DashboardBlock>> mergeMetrics(List<List<DashboardBlock>> rows) {
  final merged = <List<DashboardBlock>>[];

  for (final row in rows) {
    final joins =
        row.first.metric && merged.isNotEmpty && merged.last.first.metric;
    joins ? merged.last.addAll(row) : merged.add([...row]);
  }

  return merged;
}

const List<(DashboardBlock, DashboardBlock)> _columnPairs = [
  (DashboardBlock.salesToday, DashboardBlock.paymentMethods),
  (DashboardBlock.topProducts, DashboardBlock.lowStock),
];

List<List<DashboardBlock>> columnRows(List<DashboardBlock> blocks) {
  final placed = <DashboardBlock>{};
  final rows = <List<DashboardBlock>>[];

  for (final block in blocks) {
    if (placed.contains(block)) continue;
    final pair = _columnPairs
        .where((pair) => pair.$1 == block || pair.$2 == block)
        .firstOrNull;
    final row = pair == null
        ? [block]
        : [pair.$1, pair.$2].where(blocks.contains).toList();
    placed.addAll(row);
    rows.add(row);
  }

  return rows;
}

double stockLevel(double stock, double minimum) {
  return minimum <= 0 ? 0 : (stock / minimum).clamp(0, 1).toDouble();
}

List<DashboardLowStock> byUrgency(List<DashboardLowStock> products) {
  return [...products]..sort(
    (a, b) => stockLevel(
      a.stock,
      a.minimumStock,
    ).compareTo(stockLevel(b.stock, b.minimumStock)),
  );
}

const List<String> _weekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const List<String> _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String longDate(DateTime date) {
  return '${_weekdays[date.weekday - 1]} ${date.day} de '
      '${_months[date.month - 1]}';
}

String changeLabel(double percentage) {
  final rounded = (percentage * 10).round() / 10;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  return '${rounded > 0 ? '+' : ''}$text % vs. ayer';
}

String differenceLabel(double difference, String amount) {
  if (difference > 0) return '$amount más que ayer';
  if (difference < 0) return '$amount menos que ayer';
  return 'Igual que ayer';
}

String soldLabel(double quantity, String formatted) {
  return '$formatted ${quantity == 1 ? 'vendido' : 'vendidos'}';
}

String firstName(String fullName) => fullName.trim().split(' ').first;
