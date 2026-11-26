import 'package:casca_app/core/network/paged_response.dart';

double _amount(Object? value) => (value as num?)?.toDouble() ?? 0;

double? _optionalAmount(Object? value) => (value as num?)?.toDouble();

DateTime? _optionalDate(Object? value) {
  return value is String ? DateTime.parse(value) : null;
}

class ShiftListItemModel {
  const ShiftListItemModel({
    required this.id,
    required this.cashRegisterName,
    required this.userName,
    required this.isClosed,
    required this.initialAmount,
    required this.openedAt,
    required this.totalSales,
    this.closedAt,
    this.difference,
  });

  factory ShiftListItemModel.fromJson(Map<String, dynamic> json) {
    return ShiftListItemModel(
      id: json['cashRegisterShiftId'] as String,
      cashRegisterName: json['cashRegisterName'] as String,
      userName: json['userName'] as String? ?? '',
      isClosed: json['isClosed'] as bool,
      initialAmount: _amount(json['initialAmount']),
      openedAt: DateTime.parse(json['openedAt'] as String),
      closedAt: _optionalDate(json['closedAt']),
      totalSales: _amount(json['totalSales']),
      difference: _optionalAmount(json['difference']),
    );
  }

  final String id;
  final String cashRegisterName;
  final String userName;
  final bool isClosed;
  final double initialAmount;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double totalSales;
  final double? difference;
}

class ShiftInfoModel {
  const ShiftInfoModel({
    required this.cashRegisterName,
    required this.userName,
    required this.openedAt,
    required this.initialAmount,
    this.closedAt,
    this.expectedCash,
    this.countedCash,
    this.difference,
    this.closingNotes,
    this.closedByUserName,
    this.withdrawnAtClose,
    this.leftInCash,
    this.expectedOpeningAmount,
    this.openingDifference,
    this.openingNotes,
    this.previousClosedByUserName,
  });

  factory ShiftInfoModel.fromJson(Map<String, dynamic> json) {
    return ShiftInfoModel(
      cashRegisterName: json['cashRegisterName'] as String,
      userName: json['userName'] as String? ?? '',
      openedAt: DateTime.parse(json['openedAt'] as String),
      initialAmount: _amount(json['initialAmount']),
      closedAt: _optionalDate(json['closedAt']),
      expectedCash: _optionalAmount(json['expectedCash']),
      countedCash: _optionalAmount(json['countedCash']),
      difference: _optionalAmount(json['difference']),
      closingNotes: json['closingNotes'] as String?,
      closedByUserName: json['closedByUserName'] as String?,
      withdrawnAtClose: _optionalAmount(json['withdrawnAtClose']),
      leftInCash: _optionalAmount(json['leftInCash']),
      expectedOpeningAmount: _optionalAmount(json['expectedOpeningAmount']),
      openingDifference: _optionalAmount(json['openingDifference']),
      openingNotes: json['openingNotes'] as String?,
      previousClosedByUserName: json['previousClosedByUserName'] as String?,
    );
  }

  final String cashRegisterName;
  final String userName;
  final DateTime openedAt;
  final double initialAmount;
  final DateTime? closedAt;
  final double? expectedCash;
  final double? countedCash;
  final double? difference;
  final String? closingNotes;
  final String? closedByUserName;
  final double? withdrawnAtClose;
  final double? leftInCash;
  final double? expectedOpeningAmount;
  final double? openingDifference;
  final String? openingNotes;
  final String? previousClosedByUserName;
}

class ShiftSummaryModel {
  const ShiftSummaryModel({
    required this.cashSales,
    required this.nonCashSales,
    required this.cashIn,
    required this.cashOut,
    required this.totalSales,
  });

  factory ShiftSummaryModel.fromJson(Map<String, dynamic> json) {
    return ShiftSummaryModel(
      cashSales: _amount(json['cashSales']),
      nonCashSales: _amount(json['nonCashSales']),
      cashIn: _amount(json['cashIn']),
      cashOut: _amount(json['cashOut']),
      totalSales: _amount(json['totalSales']),
    );
  }

  final double cashSales;
  final double nonCashSales;
  final double cashIn;
  final double cashOut;
  final double totalSales;
}

class ShiftMovementModel {
  const ShiftMovementModel({
    required this.type,
    required this.amount,
    required this.createdAt,
    required this.userName,
    this.notes,
  });

  factory ShiftMovementModel.fromJson(Map<String, dynamic> json) {
    return ShiftMovementModel(
      type: json['type'] as String,
      amount: _amount(json['amount']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      userName: json['userName'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }

  final String type;
  final double amount;
  final DateTime createdAt;
  final String userName;
  final String? notes;
}

class ShiftSalePaymentModel {
  const ShiftSalePaymentModel({required this.method, required this.amount});

  factory ShiftSalePaymentModel.fromJson(Map<String, dynamic> json) {
    return ShiftSalePaymentModel(
      method: json['method'] as String,
      amount: _amount(json['amount']),
    );
  }

  final String method;
  final double amount;
}

class ShiftSaleModel {
  const ShiftSaleModel({
    required this.id,
    required this.saleNumber,
    required this.total,
    required this.createdAt,
    this.payments = const [],
  });

  factory ShiftSaleModel.fromJson(Map<String, dynamic> json) {
    return ShiftSaleModel(
      id: json['saleId'] as String,
      saleNumber: '${json['saleNumber']}',
      total: _amount(json['total']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      payments: [
        for (final item
            in json['paymentBreakdown'] as List<Object?>? ?? const [])
          ShiftSalePaymentModel.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String saleNumber;
  final double total;
  final DateTime createdAt;
  final List<ShiftSalePaymentModel> payments;
}

class ShiftPaymentCountModel {
  const ShiftPaymentCountModel({
    required this.method,
    required this.expected,
    required this.counted,
  });

  factory ShiftPaymentCountModel.fromJson(Map<String, dynamic> json) {
    return ShiftPaymentCountModel(
      method: json['method'] as int,
      expected: _amount(json['expectedAmount']),
      counted: _amount(json['countedAmount']),
    );
  }

  final int method;
  final double expected;
  final double counted;
}

class ShiftDetailModel {
  const ShiftDetailModel({
    required this.shift,
    required this.summary,
    required this.movements,
    required this.sales,
    this.paymentCounts = const [],
  });

  factory ShiftDetailModel.fromJson(Map<String, dynamic> json) {
    return ShiftDetailModel(
      shift: ShiftInfoModel.fromJson(json['shift'] as Map<String, dynamic>),
      summary: ShiftSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      movements: PagedResponse.fromJson(
        json['movements'] as Map<String, dynamic>,
        ShiftMovementModel.fromJson,
      ),
      sales: PagedResponse.fromJson(
        json['sales'] as Map<String, dynamic>,
        ShiftSaleModel.fromJson,
      ),
      paymentCounts: [
        for (final item in json['paymentCounts'] as List<Object?>? ?? const [])
          ShiftPaymentCountModel.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  final ShiftInfoModel shift;
  final ShiftSummaryModel summary;
  final PagedResponse<ShiftMovementModel> movements;
  final PagedResponse<ShiftSaleModel> sales;
  final List<ShiftPaymentCountModel> paymentCounts;
}
