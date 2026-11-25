import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_exception.dart';
import 'package:casca_app/features/products/data/models/category_model.dart';
import 'package:casca_app/features/products/presentation/providers/category_delete_provider.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
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

  String _errorMessage(Object error) {
    if (error is ApiException && error.statusCode == 403) {
      return 'No tienes permiso para eliminar categorías.';
    }
    if (error is ApiException &&
        error.type == ApiErrorType.client &&
        error.serverMessage != null) {
      return error.serverMessage!;
    }
    return 'No fue posible eliminar la categoría.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final deleteState = ref.watch(categoryDeleteControllerProvider);
    final deleting = deleteState.isLoading;
    final error = deleteState.error;

    return CascaModal(
      title: '¿Eliminar ${category.name}?',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: deleting ? null : () => Navigator.of(context).pop(false),
        ),
        CascaButton(
          label: 'Eliminar',
          variant: CascaButtonVariant.danger,
          loading: deleting,
          onPressed: () => _delete(context, ref),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Esta acción no se puede deshacer. Solo se eliminan categorías sin productos ni subcategorías.',
            style: textTheme.bodyMedium,
          ),
          if (error != null) ...[
            const SizedBox(height: CascaSpacing.space4),
            Text(
              _errorMessage(error),
              style: textTheme.bodyMedium?.copyWith(color: colors.danger),
            ),
          ],
        ],
      ),
    );
  }
}
