import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/products/data/models/product_gallery_image_model.dart';
import 'package:casca_app/features/products/data/photo_picker.dart';
import 'package:casca_app/features/products/data/product_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductImageRepository {
  const ProductImageRepository(this._api);

  final ApiClient _api;

  Future<void> uploadMainImage(String productId, PickedPhoto photo) {
    return _api.post<void>(
      ProductEndpoints.image(productId),
      body: _form(photo),
      decode: (_) {},
    );
  }

  Future<List<ProductGalleryImageModel>> getGallery(String productId) {
    return _api.get<List<ProductGalleryImageModel>>(
      ProductEndpoints.gallery(productId),
      decode: (data) {
        final images = (data as List<dynamic>)
            .map(
              (item) => ProductGalleryImageModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
        return images..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      },
    );
  }

  Future<ProductGalleryImageModel> addGalleryImage(
    String productId,
    PickedPhoto photo,
  ) {
    return _api.post<ProductGalleryImageModel>(
      ProductEndpoints.gallery(productId),
      body: _form(photo),
      decode: (data) =>
          ProductGalleryImageModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<void> reorderGallery(String productId, List<String> imageIds) {
    return _api.put<void>(
      ProductEndpoints.galleryOrder(productId),
      body: {'galleryImageIds': imageIds},
      decode: (_) {},
    );
  }

  Future<void> deleteGalleryImage(String productId, String imageId) {
    return _api.delete(ProductEndpoints.galleryImage(productId, imageId));
  }

  FormData _form(PickedPhoto photo) {
    return FormData.fromMap({
      'imageFile': MultipartFile.fromBytes(
        photo.bytes,
        filename: photo.name,
        contentType: _contentType(photo.name),
      ),
    });
  }

  DioMediaType _contentType(String name) {
    final extension = name.split('.').last.toLowerCase();
    return DioMediaType('image', switch (extension) {
      'png' => 'png',
      'webp' => 'webp',
      'heic' => 'heic',
      'heif' => 'heif',
      _ => 'jpeg',
    });
  }
}

final productImageRepositoryProvider = Provider<ProductImageRepository>(
  (ref) => ProductImageRepository(ref.watch(apiClientProvider)),
);
