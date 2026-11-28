abstract final class ProductEndpoints {
  static const String list = '/api/v1/products';

  static String byId(String productId) => '$list/$productId';

  static String image(String productId) => '${byId(productId)}/image';

  static String gallery(String productId) => '${byId(productId)}/gallery';

  static String galleryOrder(String productId) => '${gallery(productId)}/order';

  static String galleryImage(String productId, String imageId) =>
      '${gallery(productId)}/$imageId';

  static String variants(String productId) => '${byId(productId)}/variants';

  static String variant(String productId, String variantId) =>
      '${variants(productId)}/$variantId';

  static String variantPrices(String productId) =>
      '${variants(productId)}/prices';

  static String variantStatus(String productId, String variantId) =>
      '${variant(productId, variantId)}/status';

  static String variantImage(String productId, String variantId) =>
      '${variant(productId, variantId)}/image';

  static String variantSaleUnit(
    String productId,
    String variantId,
    String saleUnitId,
  ) => '${variant(productId, variantId)}/sale-units/$saleUnitId';

  static String optionOrder(String productId) =>
      '${byId(productId)}/options/order';

  static String optionValues(String productId) =>
      '${byId(productId)}/option-values';

  static String variantLimits(String productId, String variantId) =>
      '/api/v1/inventories/$productId/variants/$variantId/limits';

  static String movements(String productId) =>
      '/api/v1/inventories/$productId/movements';

  static String variantMovements(String productId, String variantId) =>
      '/api/v1/inventories/$productId/variants/$variantId/movements';
}
