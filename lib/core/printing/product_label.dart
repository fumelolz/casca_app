const int maxLabelCopies = 100;

class ProductLabel {
  const ProductLabel({
    required this.name,
    required this.sku,
    required this.price,
    this.barcode,
    this.stock = 0,
  });

  final String name;
  final String sku;
  final String? barcode;
  final double price;
  final double stock;
}

enum LabelField {
  name('Nombre'),
  sku('SKU'),
  price('Precio público'),
  barcode('Código de barras');

  const LabelField(this.label);

  final String label;
}

class LabelSize {
  const LabelSize({this.widthMm = 51, this.heightMm = 25});

  static const int minWidthMm = 25;
  static const int maxWidthMm = 108;
  static const int minHeightMm = 15;
  static const int maxHeightMm = 200;

  final int widthMm;
  final int heightMm;

  static bool isValidWidth(int? value) {
    return value != null && value >= minWidthMm && value <= maxWidthMm;
  }

  static bool isValidHeight(int? value) {
    return value != null && value >= minHeightMm && value <= maxHeightMm;
  }
}
