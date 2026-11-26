import 'dart:async';

import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/sales/data/models/sale_history_model.dart';
import 'package:casca_app/features/sales/data/sales_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int salesPageSize = 10;

class SalesQuery {
  const SalesQuery({
    this.search = '',
    this.page = 1,
    this.sort,
    this.descending = true,
  });

  final String search;
  final int page;
  final SaleSortField? sort;
  final bool descending;
}

class SalesQueryController extends Notifier<SalesQuery> {
  static const Duration searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  @override
  SalesQuery build() {
    ref.watch(
      authControllerProvider.select(
        (s) => (s.session?.account.id, s.session?.activeStore.id),
      ),
    );
    ref.onDispose(() => _searchTimer?.cancel());
    return const SalesQuery();
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final search = value.trim();
      if (search == state.search) return;
      state = SalesQuery(
        search: search,
        sort: state.sort,
        descending: state.descending,
      );
    });
  }

  void setPage(int page) {
    state = SalesQuery(
      search: state.search,
      page: page,
      sort: state.sort,
      descending: state.descending,
    );
  }

  void setSort(SaleSortField? sort, {bool descending = true}) {
    state = SalesQuery(
      search: state.search,
      sort: sort,
      descending: descending,
    );
  }
}

final salesQueryProvider = NotifierProvider<SalesQueryController, SalesQuery>(
  SalesQueryController.new,
);

final salesListProvider =
    FutureProvider.autoDispose<PagedResponse<SaleListItemModel>>(
      retry: (_, _) => null,
      (ref) {
        final query = ref.watch(salesQueryProvider);
        return ref
            .watch(salesRepositoryProvider)
            .getSales(
              page: query.page,
              pageSize: salesPageSize,
              search: query.search,
              sort: query.sort ?? SaleSortField.created,
              descending: query.descending,
            );
      },
    );

final saleDetailProvider = FutureProvider.autoDispose
    .family<SaleDetailModel, String>(retry: (_, _) => null, (ref, saleId) {
      ref.watch(
        authControllerProvider.select((s) => s.session?.activeStore.id),
      );
      return ref.watch(salesRepositoryProvider).getSale(saleId);
    });
