import 'dart:async';

import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/cash_registers/data/cash_register_repository.dart';
import 'package:casca_app/features/cash_registers/data/models/cash_register_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CashRegisterStatusFilter {
  all('Todas', null),
  open('Abiertas', true),
  closed('Cerradas', false);

  const CashRegisterStatusFilter(this.label, this.isOpen);

  final String label;
  final bool? isOpen;
}

class CashRegisterListQuery {
  const CashRegisterListQuery({
    this.search = '',
    this.status = CashRegisterStatusFilter.all,
    this.page = 1,
    this.pageSize = 10,
    this.descending = false,
  });

  final String search;
  final CashRegisterStatusFilter status;
  final int page;
  final int pageSize;
  final bool descending;

  CashRegisterListQuery copyWith({
    String? search,
    CashRegisterStatusFilter? status,
    int? page,
    bool? descending,
  }) {
    return CashRegisterListQuery(
      search: search ?? this.search,
      status: status ?? this.status,
      page: page ?? this.page,
      pageSize: pageSize,
      descending: descending ?? this.descending,
    );
  }
}

class CashRegisterListQueryController extends Notifier<CashRegisterListQuery> {
  static const Duration searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  @override
  CashRegisterListQuery build() {
    ref.onDispose(() => _searchTimer?.cancel());
    return const CashRegisterListQuery();
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final search = value.trim();
      if (search == state.search) return;
      state = state.copyWith(search: search, page: 1);
    });
  }

  void setStatus(CashRegisterStatusFilter status) {
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

final cashRegisterListQueryProvider =
    NotifierProvider.autoDispose<
      CashRegisterListQueryController,
      CashRegisterListQuery
    >(CashRegisterListQueryController.new);

final cashRegisterListProvider =
    FutureProvider.autoDispose<PagedResponse<CashRegisterModel>>(
      retry: (_, _) => null,
      (ref) {
        final query = ref.watch(cashRegisterListQueryProvider);
        return ref
            .watch(cashRegisterRepositoryProvider)
            .getCashRegisters(
              search: query.search,
              isOpen: query.status.isOpen,
              page: query.page,
              pageSize: query.pageSize,
              descending: query.descending,
            );
      },
    );
