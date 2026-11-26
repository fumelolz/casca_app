abstract final class PosEndpoints {
  static const String catalog = '/api/v1/pos/catalog';

  static const String exactItem = '$catalog/exact';

  static const String sales = '/api/v1/sales';

  static const String salePreview = '$sales/preview';

  static const String priceLists = '/api/v1/price-lists';

  static const String activeShift = '/api/v1/cash-registers/active';
}
