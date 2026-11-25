import 'dart:async';

import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/stores/data/models/store_list_item_model.dart';
import 'package:casca_app/features/stores/data/store_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StoreStatusFilter {
  all('Todas', null),
  active('Activas', true),
  inactive('Inactivas', false);

  const StoreStatusFilter(this.label, this.isActive);

  final String label;
  final bool? isActive;
}

class StoreListQuery {
  const StoreListQuery({
    this.search = '',
    this.status = StoreStatusFilter.all,
    this.page = 1,
    this.pageSize = 10,
    this.descending = false,
  });

  final String search;
  final StoreStatusFilter status;
  final int page;
  final int pageSize;
  final bool descending;

  StoreListQuery copyWith({
    String? search,
    StoreStatusFilter? status,
    int? page,
    bool? descending,
  }) {
    return StoreListQuery(
      search: search ?? this.search,
      status: status ?? this.status,
      page: page ?? this.page,
      pageSize: pageSize,
      descending: descending ?? this.descending,
    );
  }
}

class StoreListQueryController extends Notifier<StoreListQuery> {
  static const Duration searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  @override
  StoreListQuery build() {
    ref.onDispose(() => _searchTimer?.cancel());
    return const StoreListQuery();
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final search = value.trim();
      if (search == state.search) return;
      state = state.copyWith(search: search, page: 1);
    });
  }

  void setStatus(StoreStatusFilter status) {
    if (status == state.status) return;
    state = state.copyWith(status: status, page: 1);
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

final storeListQueryProvider =
    NotifierProvider.autoDispose<StoreListQueryController, StoreListQuery>(
      StoreListQueryController.new,
    );

final storeListProvider =
    FutureProvider.autoDispose<PagedResponse<StoreListItemModel>>(
      retry: (_, _) => null,
      (ref) {
        final query = ref.watch(storeListQueryProvider);
        return ref
            .watch(storeRepositoryProvider)
            .getStores(
              search: query.search,
              isActive: query.status.isActive,
              page: query.page,
              pageSize: query.pageSize,
              descending: query.descending,
            );
      },
    );
