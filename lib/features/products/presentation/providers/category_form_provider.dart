import 'package:casca_app/features/products/data/category_repository.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/data/models/category_request.dart';
import 'package:casca_app/features/products/presentation/providers/category_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _parentOptionsPageSize = 100;

class CategoryFormController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> save(CategoryRequest request, {String? categoryId}) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final keepAlive = ref.keepAlive();
    final repository = ref.read(categoryRepositoryProvider);
    final result = await AsyncValue.guard(
      () => categoryId == null
          ? repository.createCategory(request)
          : repository.updateCategory(categoryId, request),
    );
    if (ref.mounted) {
      if (!result.hasError) ref.invalidate(categoryListProvider);
      state = result;
    }
    keepAlive.close();
    return !result.hasError;
  }
}

final categoryFormControllerProvider =
    NotifierProvider.autoDispose<CategoryFormController, AsyncValue<void>>(
      CategoryFormController.new,
    );

final categoryParentOptionsProvider =
    FutureProvider.autoDispose<List<CategoryModel>>(retry: (_, _) => null, (
      ref,
    ) async {
      final page = await ref
          .watch(categoryRepositoryProvider)
          .getCategories(pageSize: _parentOptionsPageSize, rootOnly: true);
      return page.items;
    });
