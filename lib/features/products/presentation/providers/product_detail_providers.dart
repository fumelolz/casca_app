import 'package:casca_app/features/products/data/models/inventory_movement_model.dart';
import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/features/products/data/product_image_repository.dart';
import 'package:casca_app/features/products/data/product_repository.dart';
import 'package:casca_app/features/products/presentation/providers/product_form_provider.dart';
import 'package:casca_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _movementsPageSize = 10;

final productGalleryProvider = FutureProvider.autoDispose
    .family<List<ProductImageModel>, String>(
      retry: (_, _) => null,
      (ref, productId) async {
        final gallery = await ref
            .watch(productImageRepositoryProvider)
            .getGallery(productId);
        return [for (final item in gallery) item.image];
      },
    );

class ProductMovementsState {
  const ProductMovementsState({
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.hasNextPage = false,
    this.loading = false,
    this.error,
  });

  final List<InventoryMovementModel> items;
  final int page;
  final int totalCount;
  final bool hasNextPage;
  final bool loading;
  final Object? error;

  ProductMovementsState copyWith({
    List<InventoryMovementModel>? items,
    int? page,
    int? totalCount,
    bool? hasNextPage,
    bool? loading,
    Object? error,
  }) {
    return ProductMovementsState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class ProductMovementsController extends Notifier<ProductMovementsState> {
  ProductMovementsController(this.productId);

  final String productId;
  int _request = 0;

  @override
  ProductMovementsState build() {
    Future.microtask(reload);
    return const ProductMovementsState(loading: true);
  }

  Future<void> reload() => _load(1);

  Future<void> loadMore() async {
    if (state.loading || !state.hasNextPage) return;
    await _load(state.page + 1);
  }

  Future<void> _load(int page) async {
    if (!ref.mounted) return;
    final request = ++_request;
    state = state.copyWith(loading: true);
    try {
      final result = await ref
          .read(productRepositoryProvider)
          .getMovements(productId, page: page, pageSize: _movementsPageSize);
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(
        items: page == 1 ? result.items : [...state.items, ...result.items],
        page: page,
        totalCount: result.totalCount,
        hasNextPage: result.hasNextPage,
        loading: false,
      );
    } catch (error) {
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(loading: false, error: error);
    }
  }
}

final productMovementsProvider = NotifierProvider.autoDispose
    .family<ProductMovementsController, ProductMovementsState, String>(
      ProductMovementsController.new,
    );

class InventoryMovementController extends Notifier<AsyncValue<void>> {
  InventoryMovementController(this.productId);

  final String productId;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save(Map<String, dynamic> request, {String? variantId}) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final result = await AsyncValue.guard(
      () => ref
          .read(productRepositoryProvider)
          .addMovement(productId, request, variantId: variantId),
    );
    if (ref.mounted) {
      if (!result.hasError) {
        ref.invalidate(productListProvider);
        ref.invalidate(productDetailProvider(productId));
        ref.invalidate(productMovementsProvider(productId));
      }
      state = result;
    }
    keepAlive.close();
    return !result.hasError;
  }
}

final inventoryMovementControllerProvider = NotifierProvider.autoDispose
    .family<InventoryMovementController, AsyncValue<void>, String>(
      InventoryMovementController.new,
    );

class ProductDeleteController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> delete(String productId, int version) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final result = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).deleteProduct(productId, version),
    );
    if (ref.mounted) {
      if (!result.hasError) ref.invalidate(productListProvider);
      state = result;
    }
    keepAlive.close();
    return !result.hasError;
  }
}

final productDeleteControllerProvider =
    NotifierProvider.autoDispose<ProductDeleteController, AsyncValue<void>>(
      ProductDeleteController.new,
    );
