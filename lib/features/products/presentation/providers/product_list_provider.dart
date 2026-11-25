import 'dart:async';

import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/features/products/data/product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductListQuery {
  const ProductListQuery({
    this.search = '',
    this.page = 1,
    this.pageSize = 10,
    this.sort = ProductSortField.created,
    this.descending = true,
  });

  final String search;
  final int page;
  final int pageSize;
  final ProductSortField sort;
  final bool descending;

  ProductListQuery copyWith({
    String? search,
    int? page,
    ProductSortField? sort,
    bool? descending,
  }) {
    return ProductListQuery(
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize,
      sort: sort ?? this.sort,
      descending: descending ?? this.descending,
    );
  }
}

class ProductListQueryController extends Notifier<ProductListQuery> {
  static const Duration searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  @override
  ProductListQuery build() {
    ref.onDispose(() => _searchTimer?.cancel());
    return const ProductListQuery();
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final search = value.trim();
      if (search == state.search) return;
      state = state.copyWith(search: search, page: 1);
    });
  }

  void setPage(int page) {
    if (page == state.page) return;
    state = state.copyWith(page: page);
  }

  void setSort(ProductSortField sort, {required bool descending}) {
    if (sort == state.sort && descending == state.descending) return;
    state = state.copyWith(sort: sort, descending: descending, page: 1);
  }

  void resetSort() => setSort(ProductSortField.created, descending: true);
}

final productListQueryProvider =
    NotifierProvider.autoDispose<ProductListQueryController, ProductListQuery>(
      ProductListQueryController.new,
    );

final productListProvider =
    FutureProvider.autoDispose<PagedResponse<ProductListItemModel>>(
      retry: (_, _) => null,
      (ref) {
        final query = ref.watch(productListQueryProvider);
        return ref
            .watch(productRepositoryProvider)
            .getProducts(
              search: query.search,
              page: query.page,
              pageSize: query.pageSize,
              sort: query.sort,
              descending: query.descending,
            );
      },
    );
