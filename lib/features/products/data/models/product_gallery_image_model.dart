import 'package:casca_app/features/products/data/models/product_list_item_model.dart';

class ProductGalleryImageModel {
  const ProductGalleryImageModel({
    required this.id,
    required this.image,
    required this.sortOrder,
  });

  factory ProductGalleryImageModel.fromJson(Map<String, dynamic> json) {
    return ProductGalleryImageModel(
      id: json['id'] as String,
      image: ProductImageModel.fromJson(json['image'] as Map<String, dynamic>),
      sortOrder: json['sortOrder'] as int,
    );
  }

  final String id;
  final ProductImageModel image;
  final int sortOrder;
}
