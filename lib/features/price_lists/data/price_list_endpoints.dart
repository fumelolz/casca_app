abstract final class PriceListEndpoints {
  static const String list = '/api/v1/price-lists';

  static const String sellableItems = '/api/v1/pos/catalog';

  static String byId(String priceListId) => '$list/$priceListId';

  static String prices(String priceListId) => '${byId(priceListId)}/prices';
}
