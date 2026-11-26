import 'dart:async';

import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/network/paged_response.dart';
import 'package:casca_app/features/price_lists/data/models/price_list_model.dart';
import 'package:casca_app/features/price_lists/data/price_list_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int priceItemsPageSize = 25;

final priceListsProvider = FutureProvider.autoDispose<List<PriceListModel>>(
  retry: (_, _) => null,
  (ref) => ref.watch(priceListRepositoryProvider).getAll(),
);

final priceListProvider = FutureProvider.autoDispose
    .family<PriceListModel, String>(
      retry: (_, _) => null,
      (ref, id) => ref.watch(priceListRepositoryProvider).getById(id),
    );

class PriceListActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<PriceListModel?> save(String name, {String? priceListId}) async {
    PriceListModel? saved;
    await _run(() async {
      final repository = ref.read(priceListRepositoryProvider);
      saved = priceListId == null
          ? await repository.create(name)
          : await repository.rename(priceListId, name);
    });
    final id = priceListId;
    if (saved != null && id != null && ref.mounted) {
      ref.invalidate(priceListProvider(id));
    }
    return saved;
  }

  Future<bool> delete(String priceListId) {
    return _run(
      () => ref.read(priceListRepositoryProvider).delete(priceListId),
    );
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) {
      if (!result.hasError) ref.invalidate(priceListsProvider);
      state = result;
    }
    keepAlive.close();
    return !result.hasError;
  }
}

final priceListActionProvider =
    NotifierProvider.autoDispose<PriceListActionController, AsyncValue<void>>(
      PriceListActionController.new,
    );

class PriceItemsQuery {
  const PriceItemsQuery({this.search = '', this.page = 1});

  final String search;
  final int page;
}

class PriceItemsQueryController extends Notifier<PriceItemsQuery> {
  static const Duration searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;

  @override
  PriceItemsQuery build() {
    ref.onDispose(() => _searchTimer?.cancel());
    return const PriceItemsQuery();
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final search = value.trim();
      if (search == state.search) return;
      state = PriceItemsQuery(search: search);
    });
  }

  void setPage(int page) {
    if (page == state.page) return;
    state = PriceItemsQuery(search: state.search, page: page);
  }
}

final priceItemsQueryProvider =
    NotifierProvider.autoDispose<PriceItemsQueryController, PriceItemsQuery>(
      PriceItemsQueryController.new,
    );

final priceItemsProvider =
    FutureProvider.autoDispose<PagedResponse<PriceListItemModel>>(
      retry: (_, _) => null,
      (ref) {
        ref.watch(
          authControllerProvider.select((s) => s.session?.activeStore.id),
        );
        final query = ref.watch(priceItemsQueryProvider);
        return ref
            .watch(priceListRepositoryProvider)
            .getItems(
              search: query.search,
              page: query.page,
              pageSize: priceItemsPageSize,
            );
      },
    );
