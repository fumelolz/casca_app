import 'package:casca_app/features/price_lists/data/price_list_repository.dart';
import 'package:casca_app/features/price_lists/domain/price_list_rules.dart';
import 'package:casca_app/features/price_lists/presentation/providers/price_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PriceEditorState {
  const PriceEditorState({
    this.saved,
    this.pending = const {},
    this.saving = false,
    this.loadError,
    this.saveError,
  });

  final Map<String, double>? saved;
  final PriceChanges pending;
  final bool saving;
  final Object? loadError;
  final Object? saveError;

  PriceEditorState copyWith({
    Map<String, double>? saved,
    PriceChanges? pending,
    bool? saving,
    Object? loadError,
    Object? saveError,
  }) {
    return PriceEditorState(
      saved: saved ?? this.saved,
      pending: pending ?? this.pending,
      saving: saving ?? this.saving,
      loadError: loadError,
      saveError: saveError,
    );
  }
}

class PriceEditorController extends Notifier<PriceEditorState> {
  PriceEditorController(this.priceListId);

  final String priceListId;

  @override
  PriceEditorState build() {
    Future.microtask(load);
    return const PriceEditorState();
  }

  Future<void> load() async {
    if (!ref.mounted) return;
    try {
      final saved = await ref
          .read(priceListRepositoryProvider)
          .getPrices(priceListId);
      if (!ref.mounted) return;
      state = state.copyWith(saved: saved, saveError: state.saveError);
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(loadError: error, saveError: state.saveError);
    }
  }

  void setPrice(String sellableItemId, double? price) {
    final saved = state.saved;
    if (saved == null || state.saving) return;
    state = state.copyWith(
      pending: withPendingChange(state.pending, saved, sellableItemId, price),
    );
  }

  void discard() => state = state.copyWith(pending: const {});

  Future<bool> save() async {
    if (state.saving || state.pending.isEmpty) return false;
    final keepAlive = ref.keepAlive();
    final repository = ref.read(priceListRepositoryProvider);
    state = state.copyWith(saving: true);
    try {
      for (final batch in priceBatches(state.pending)) {
        await repository.setPrices(priceListId, toPriceRequests(batch));
        if (!ref.mounted) return false;
        state = state.copyWith(
          saved: applyChanges(state.saved ?? const {}, batch),
          pending: {...state.pending}
            ..removeWhere((id, _) => batch.containsKey(id)),
        );
      }
      state = state.copyWith(saving: false);
      ref
        ..invalidate(priceListProvider(priceListId))
        ..invalidate(priceListsProvider);
      return true;
    } catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(saving: false, saveError: error);
      await load();
      return false;
    } finally {
      keepAlive.close();
    }
  }
}

final priceEditorProvider = NotifierProvider.autoDispose
    .family<PriceEditorController, PriceEditorState, String>(
      PriceEditorController.new,
    );
