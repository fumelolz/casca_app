import 'package:casca_app/features/stores/data/store_repository.dart';
import 'package:casca_app/features/stores/presentation/providers/store_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>(
      retry: (_, _) => null,
      (ref, storeId) => ref.watch(storeRepositoryProvider).getStore(storeId),
    );

class StoreFormController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save(Map<String, dynamic> request, {String? storeId}) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final repository = ref.read(storeRepositoryProvider);
    final result = await AsyncValue.guard(
      () => storeId == null
          ? repository.createStore(request)
          : repository.updateStore(storeId, request),
    );
    if (ref.mounted) {
      if (!result.hasError) ref.invalidate(storeListProvider);
      state = result;
    }
    keepAlive.close();
    return !result.hasError;
  }
}

final storeFormControllerProvider =
    NotifierProvider.autoDispose<StoreFormController, AsyncValue<void>>(
      StoreFormController.new,
    );
