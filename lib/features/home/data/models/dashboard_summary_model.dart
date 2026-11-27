double _number(Object? value) => (value as num?)?.toDouble() ?? 0;

List<T> _items<T>(Object? value, T Function(Map<String, dynamic>) fromJson) {
  return [
    for (final item in (value as List<Object?>?) ?? const [])
      fromJson(item as Map<String, dynamic>),
  ];
}

class DashboardProductSale {
  const DashboardProductSale({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  factory DashboardProductSale.fromJson(Map<String, dynamic> json) {
    return DashboardProductSale(
      name: json['name'] as String,
      quantity: _number(json['quantity']),
      revenue: _number(json['revenue']),
    );
  }

  final String name;
  final double quantity;
  final double revenue;
}

class DashboardLowStock {
  const DashboardLowStock({
    required this.name,
    required this.stock,
    required this.minimumStock,
  });

  factory DashboardLowStock.fromJson(Map<String, dynamic> json) {
    return DashboardLowStock(
      name: json['name'] as String,
      stock: _number(json['stock']),
      minimumStock: _number(json['minimumStock']),
    );
  }

  final String name;
  final double stock;
  final double minimumStock;
}

class DashboardPayment {
  const DashboardPayment({required this.method, required this.total});

  factory DashboardPayment.fromJson(Map<String, dynamic> json) {
    return DashboardPayment(
      method: json['method'] as String,
      total: _number(json['total']),
    );
  }

  final String method;
  final double total;
}

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.todayTotal,
    required this.todayOrders,
    required this.averageTicket,
    required this.yesterdayTotal,
    required this.percentageChange,
    required this.todayProfit,
    this.topProducts = const [],
    this.lowStock = const [],
    this.payments = const [],
    this.generatedAt,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final sales = json['sales'] as Map<String, dynamic>;
    final profit = json['profit'] as Map<String, dynamic>?;

    return DashboardSummaryModel(
      todayTotal: _number(sales['todayTotal']),
      todayOrders: (sales['todayOrders'] as num?)?.toInt() ?? 0,
      averageTicket: _number(sales['avgTicket']),
      yesterdayTotal: _number(sales['yesterdayTotal']),
      percentageChange: _number(sales['percentageChange']),
      todayProfit: _number(profit?['todayProfit']),
      topProducts: _items(json['topProducts'], DashboardProductSale.fromJson),
      lowStock: _items(json['lowStock'], DashboardLowStock.fromJson),
      payments: _items(json['paymentMethods'], DashboardPayment.fromJson),
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? ''),
    );
  }

  final double todayTotal;
  final int todayOrders;
  final double averageTicket;
  final double yesterdayTotal;
  final double percentageChange;
  final double todayProfit;
  final List<DashboardProductSale> topProducts;
  final List<DashboardLowStock> lowStock;
  final List<DashboardPayment> payments;
  final DateTime? generatedAt;
}
