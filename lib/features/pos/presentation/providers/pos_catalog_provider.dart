import 'dart:async';

import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/data/pos_repository.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PosCatalogState {
  const PosCatalogState({
    this.items = const [],
    this.search = '',
    this.page = 1,
    this.hasNextPage = false,
    this.loading = false,
    this.error,
  });

  final List<PosCatalogItemModel> items;
  final String search;
  final int page;
  final bool hasNextPage;
  final bool loading;
  final Object? error;

  PosCatalogState copyWith({
    List<PosCatalogItemModel>? items,
    String? search,
    int? page,
    bool? hasNextPage,
    bool? loading,
    Object? error,
  }) {
    return PosCatalogState(
      items: items ?? this.items,
      search: search ?? this.search,
      page: page ?? this.page,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class PosCatalogController extends Notifier<PosCatalogState> {
  static const Duration searchDelay = Duration(milliseconds: 300);

  Timer? _searchTimer;
  int _request = 0;

  @override
  PosCatalogState build() {
    ref.watch(authControllerProvider.select((s) => s.session?.activeStore.id));
    ref.listen(cartProvider.select((cart) => cart.priceListId), (_, _) {
      state = state.copyWith(items: const []);
      reload();
    });
    ref.onDispose(() => _searchTimer?.cancel());
    Future.microtask(reload);
    return const PosCatalogState(loading: true);
  }

  void setSearch(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDelay, () {
      final search = value.trim();
      if (search == state.search) return;
      state = state.copyWith(search: search, items: const []);
      reload();
    });
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
          .read(posRepositoryProvider)
          .catalog(
            state.search,
            page,
            priceListId: ref.read(cartProvider).priceListId,
          );
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(
        items: page == 1 ? result.items : [...state.items, ...result.items],
        page: page,
        hasNextPage: result.hasNextPage,
        loading: false,
      );
    } catch (error) {
      if (!ref.mounted || request != _request) return;
      state = state.copyWith(loading: false, error: error);
    }
  }
}

final posCatalogProvider =
    NotifierProvider.autoDispose<PosCatalogController, PosCatalogState>(
      PosCatalogController.new,
    );

final activeShiftProvider = FutureProvider.autoDispose<bool>(
  retry: (_, _) => null,
  (ref) {
    ref.watch(authControllerProvider.select((s) => s.session?.activeStore.id));
    return ref.watch(posRepositoryProvider).hasActiveShift();
  },
);
