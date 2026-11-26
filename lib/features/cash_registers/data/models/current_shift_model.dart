double _amount(Object? value) => (value as num?)?.toDouble() ?? 0;

class CurrentShiftModel {
  const CurrentShiftModel({
    required this.shiftId,
    required this.cashRegisterName,
    required this.openedAt,
    required this.initialAmount,
    required this.summary,
    this.expectedOpeningAmount,
    this.openingDifference,
    this.openingNotes,
    this.previousClosedByUserName,
  });

  factory CurrentShiftModel.fromJson(Map<String, dynamic> json) {
    return CurrentShiftModel(
      shiftId: json['cashRegisterShiftId'] as String,
      cashRegisterName: json['cashRegisterName'] as String,
      openedAt: DateTime.parse(json['openedAt'] as String),
      initialAmount: _amount(json['initialAmount']),
      summary: CurrentShiftSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      expectedOpeningAmount: (json['expectedOpeningAmount'] as num?)
          ?.toDouble(),
      openingDifference: (json['openingDifference'] as num?)?.toDouble(),
      openingNotes: json['openingNotes'] as String?,
      previousClosedByUserName: json['previousClosedByUserName'] as String?,
    );
  }

  final String shiftId;
  final String cashRegisterName;
  final DateTime openedAt;
  final double initialAmount;
  final CurrentShiftSummaryModel summary;
  final double? expectedOpeningAmount;
  final double? openingDifference;
  final String? openingNotes;
  final String? previousClosedByUserName;
}

class CurrentShiftSummaryModel {
  const CurrentShiftSummaryModel({
    required this.cashSales,
    required this.transferSales,
    required this.creditCardSales,
    required this.debitCardSales,
    required this.cashIn,
    required this.cashOut,
    required this.expectedCash,
    required this.totalSales,
  });

  factory CurrentShiftSummaryModel.fromJson(Map<String, dynamic> json) {
    return CurrentShiftSummaryModel(
      cashSales: _amount(json['cashSales']),
      transferSales: _amount(json['transferSales']),
      creditCardSales: _amount(json['creditCardSales']),
      debitCardSales: _amount(json['debitCardSales']),
      cashIn: _amount(json['cashIn']),
      cashOut: _amount(json['cashOut']),
      expectedCash: _amount(json['expectedCash']),
      totalSales: _amount(json['totalSales']),
    );
  }

  final double cashSales;
  final double transferSales;
  final double creditCardSales;
  final double debitCardSales;
  final double cashIn;
  final double cashOut;
  final double expectedCash;
  final double totalSales;
}

class AvailableCashRegisterModel {
  const AvailableCashRegisterModel({
    required this.id,
    required this.name,
    this.suggestedInitialAmount,
  });

  factory AvailableCashRegisterModel.fromJson(Map<String, dynamic> json) {
    return AvailableCashRegisterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      suggestedInitialAmount: (json['suggestedInitialAmount'] as num?)
          ?.toDouble(),
    );
  }

  final String id;
  final String name;
  final double? suggestedInitialAmount;
}

class ClosedShiftModel {
  const ClosedShiftModel({
    required this.shiftId,
    required this.countedCash,
    required this.difference,
    required this.totalSales,
    required this.withdrawnAtClose,
    required this.leftInCash,
  });

  factory ClosedShiftModel.fromJson(Map<String, dynamic> json) {
    return ClosedShiftModel(
      shiftId: json['cashRegisterShiftId'] as String,
      countedCash: _amount(json['countedCash']),
      difference: _amount(json['difference']),
      totalSales: _amount(json['totalSales']),
      withdrawnAtClose: _amount(json['withdrawnAtClose']),
      leftInCash: _amount(json['leftInCash']),
    );
  }

  final String shiftId;
  final double countedCash;
  final double difference;
  final double totalSales;
  final double withdrawnAtClose;
  final double leftInCash;
}
