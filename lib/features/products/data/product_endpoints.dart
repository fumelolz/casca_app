abstract final class ProductEndpoints {
  static const String list = '/api/v1/products';

  static String byId(String productId) => '$list/$productId';

  static String image(String productId) => '${byId(productId)}/image';

  static String gallery(String productId) => '${byId(productId)}/gallery';

  static String galleryOrder(String productId) => '${gallery(productId)}/order';

  static String galleryImage(String productId, String imageId) =>
      '${gallery(productId)}/$imageId';
}
