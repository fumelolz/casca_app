import 'dart:async';

import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/products/data/category_repository.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryListQuery {
  const CategoryListQuery({
    this.search = '',
    this.page = 1,
    this.pageSize = 10,
  });

  final String search;
  final int page;
  final int pageSize;
}

class CategoryListQueryController extends Notifier<CategoryListQuery> {
  static const Duration searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  @override
  CategoryListQuery build() {
    ref.onDispose(() => _searchTimer?.cancel());
    return const CategoryListQuery();
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final search = value.trim();
      if (search == state.search) return;
      state = CategoryListQuery(search: search, pageSize: state.pageSize);
    });
  }

  void setPage(int page) {
    if (page == state.page) return;
    state = CategoryListQuery(
      search: state.search,
      page: page,
      pageSize: state.pageSize,
    );
  }
}

final categoryListQueryProvider =
    NotifierProvider.autoDispose<
      CategoryListQueryController,
      CategoryListQuery
    >(CategoryListQueryController.new);

final categoryListProvider =
    FutureProvider.autoDispose<PagedResponse<CategoryModel>>(
      retry: (_, _) => null,
      (ref) {
        final query = ref.watch(categoryListQueryProvider);
        return ref
            .watch(categoryRepositoryProvider)
            .getCategories(
              search: query.search,
              page: query.page,
              pageSize: query.pageSize,
            );
      },
    );
