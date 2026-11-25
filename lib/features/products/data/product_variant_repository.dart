import 'package:casca_app/core/network/api_client.dart';
import 'package:casca_app/core/network/network_providers.dart';
import 'package:casca_app/features/products/data/product_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductVariantRepository {
  const ProductVariantRepository(this._api);

  final ApiClient _api;

  Future<void> addVariants(String productId, Map<String, dynamic> request) {
    return _api.post<void>(
      ProductEndpoints.variants(productId),
      body: request,
      decode: (_) {},
    );
  }

  Future<void> changePrices(String productId, Map<String, dynamic> request) {
    return _put(ProductEndpoints.variantPrices(productId), request);
  }

  Future<void> reorderOptions(String productId, Map<String, dynamic> request) {
    return _put(ProductEndpoints.optionOrder(productId), request);
  }

  Future<void> renameOptionValue(
    String productId,
    Map<String, dynamic> request,
  ) {
    return _put(ProductEndpoints.optionValues(productId), request);
  }

  Future<void> updateVariant(
    String productId,
    String variantId,
    Map<String, dynamic> request,
  ) {
    return _put(ProductEndpoints.variant(productId, variantId), request);
  }

  Future<void> changeStatus(
    String productId,
    String variantId,
    Map<String, dynamic> request,
  ) {
    return _put(ProductEndpoints.variantStatus(productId, variantId), request);
  }

  Future<void> updateSaleUnit(
    String productId,
    String variantId,
    String saleUnitId,
    Map<String, dynamic> request,
  ) {
    return _put(
      ProductEndpoints.variantSaleUnit(productId, variantId, saleUnitId),
      request,
    );
  }

  Future<void> updateLimits(
    String productId,
    String variantId,
    Map<String, dynamic> request,
  ) {
    return _put(ProductEndpoints.variantLimits(productId, variantId), request);
  }

  Future<void> _put(String path, Map<String, dynamic> request) {
    return _api.put<void>(path, body: request, decode: (_) {});
  }
}

final productVariantRepositoryProvider = Provider<ProductVariantRepository>(
  (ref) => ProductVariantRepository(ref.watch(apiClientProvider)),
);
