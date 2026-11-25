import 'package:casca_app/features/products/data/category_repository.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/data/product_repository.dart';
import 'package:casca_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _categoryOptionsPageSize = 100;

final productDetailProvider = FutureProvider.autoDispose
    .family<ProductDetailModel, String>(
      retry: (_, _) => null,
      (ref, productId) =>
          ref.watch(productRepositoryProvider).getProduct(productId),
    );

final productCategoryOptionsProvider =
    FutureProvider.autoDispose<List<CategoryModel>>(retry: (_, _) => null, (
      ref,
    ) async {
      final page = await ref
          .watch(categoryRepositoryProvider)
          .getCategories(pageSize: _categoryOptionsPageSize);
      return page.items;
    });

class ProductFormController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> save(
    Map<String, dynamic> request, {
    String? productId,
  }) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final repository = ref.read(productRepositoryProvider);
    String? savedId;
    final result = await AsyncValue.guard(() async {
      if (productId == null) {
        savedId = await repository.createProduct(request);
        return;
      }
      await repository.updateProduct(productId, request);
      savedId = productId;
    });
    if (ref.mounted) {
      if (!result.hasError) {
        ref.invalidate(productListProvider);
        if (productId != null) {
          ref.invalidate(productDetailProvider(productId));
        }
      }
      state = result;
    }
    keepAlive.close();
    return savedId;
  }
}

final productFormControllerProvider =
    NotifierProvider.autoDispose<ProductFormController, AsyncValue<void>>(
      ProductFormController.new,
    );
