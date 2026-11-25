import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/presentation/providers/category_delete_provider.dart';
import 'package:casca_app/shared/ui/casca_delete_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class CategoryDeleteModal extends ConsumerWidget {
  const CategoryDeleteModal({super.key, required this.category});

  final CategoryModel category;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final deleted = await ref
        .read(categoryDeleteControllerProvider.notifier)
        .delete(category.id);
    if (deleted && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleteState = ref.watch(categoryDeleteControllerProvider);
    final error = deleteState.error;

    return CascaDeleteModal(
      title: '¿Eliminar ${category.name}?',
      message: 'Esta acción no se puede deshacer. Solo se eliminan categorías sin productos ni subcategorías.',
      deleting: deleteState.isLoading,
      errorMessage: error == null
          ? null
          : apiErrorMessage(
              error,
              'No fue posible eliminar la categoría.',
              forbidden: 'No tienes permiso para eliminar categorías.',
            ),
      onConfirm: () => _delete(context, ref),
    );
  }
}
