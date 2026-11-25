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
    this.descending = false,
  });

  final String search;
  final int page;
  final int pageSize;
  final bool descending;

  CategoryListQuery copyWith({String? search, int? page, bool? descending}) {
    return CategoryListQuery(
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize,
      descending: descending ?? this.descending,
    );
  }
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
      state = state.copyWith(search: search, page: 1);
    });
  }

  void setPage(int page) {
    if (page == state.page) return;
    state = state.copyWith(page: page);
  }

  void setDescending(bool descending) {
    if (descending == state.descending) return;
    state = state.copyWith(descending: descending, page: 1);
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
              descending: query.descending,
            );
      },
    );
