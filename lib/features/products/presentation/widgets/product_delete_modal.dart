import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/presentation/providers/product_detail_providers.dart';
import 'package:casca_app/shared/ui/casca_delete_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class ProductDeleteModal extends ConsumerWidget {
  const ProductDeleteModal({super.key, required this.product});

  final ProductDetailModel product;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final deleted = await ref
        .read(productDeleteControllerProvider.notifier)
        .delete(product.id, product.version);
    if (deleted && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productDeleteControllerProvider);
    final error = state.error;

    return CascaDeleteModal(
      title: '¿Eliminar ${product.name}?',
      message:
          'Esta acción no se puede deshacer. Las ventas y movimientos de inventario anteriores conservarán su información.',
      deleting: state.isLoading,
      errorMessage: error == null
          ? null
          : apiErrorMessage(
              error,
              'No fue posible eliminar el producto.',
              forbidden: 'No tienes permiso para eliminar productos.',
            ),
      onConfirm: () => _delete(context, ref),
    );
  }
}
