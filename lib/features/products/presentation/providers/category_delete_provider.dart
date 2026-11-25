import 'package:casca_app/features/products/data/category_repository.dart';
import 'package:casca_app/features/products/presentation/providers/category_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryDeleteController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> delete(String categoryId) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final repository = ref.read(categoryRepositoryProvider);
    final result = await AsyncValue.guard(
      () => repository.deleteCategory(categoryId),
    );
    if (ref.mounted) {
      if (!result.hasError) ref.invalidate(categoryListProvider);
      state = result;
    }
    keepAlive.close();
    return !result.hasError;
  }
}

final categoryDeleteControllerProvider =
    NotifierProvider.autoDispose<CategoryDeleteController, AsyncValue<void>>(
      CategoryDeleteController.new,
    );
