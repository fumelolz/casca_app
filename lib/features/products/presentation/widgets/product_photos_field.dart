import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/data/photo_picker.dart';
import 'package:casca_app/features/products/presentation/providers/product_photos_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/product_thumbnail.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_image_grid.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _PhotoSource { camera, gallery }

class ProductPhotosField extends ConsumerWidget {
  const ProductPhotosField({super.key, required this.productId});

  final String? productId;

  Future<List<PickedPhoto>> _pick(
    BuildContext context,
    WidgetRef ref, {
    required int limit,
  }) async {
    final picker = ref.read(photoPickerProvider);
    var source = _PhotoSource.gallery;

    if (picker.hasCamera) {
      final chosen = await showCascaModal<_PhotoSource>(
        context: context,
        size: CascaModalSize.sm,
        builder: (modalContext) => CascaModal(
          title: 'Agregar foto',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CascaButton(
                label: 'Tomar foto',
                fullWidth: true,
                onPressed: () =>
                    Navigator.of(modalContext).pop(_PhotoSource.camera),
              ),
              const SizedBox(height: CascaSpacing.space3),
              CascaButton(
                label: 'Elegir de la galería',
                variant: CascaButtonVariant.secondary,
                fullWidth: true,
                onPressed: () =>
                    Navigator.of(modalContext).pop(_PhotoSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (chosen == null) return const [];
      source = chosen;
    }

    if (source == _PhotoSource.camera) return [?await picker.takePhoto()];
    return picker.pickFromGallery(limit: limit);
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref, {
    String? replacing,
  }) async {
    final provider = productPhotosProvider(productId);
    final controller = ref.read(provider.notifier);
    try {
      final photos = await _pick(
        context,
        ref,
        limit: replacing != null ? 1 : ref.read(provider).freeSlots,
      );
      if (!context.mounted || photos.isEmpty) return;
      await (replacing != null
          ? controller.replace(replacing, photos.first)
          : controller.add(photos));
    } catch (error) {
      if (context.mounted) controller.report(error);
    }
  }

  Widget _picture(PhotoSlot slot, {bool fullSize = false}) {
    final local = slot.local;
    if (local != null) {
      return Image.memory(
        local.bytes,
        fit: fullSize ? BoxFit.contain : BoxFit.cover,
      );
    }
    return ProductPicture(image: slot.remote, fullSize: fullSize);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final provider = productPhotosProvider(productId);
    final photos = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final isEdit = productId != null;
    final main = photos.main;
    final error = photos.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CascaImageGrid(
          maxSecondary: maxSecondaryPhotos,
          busy: photos.busy,
          loading: photos.loading,
          main: main == null
              ? null
              : CascaImageItem(
                  id: main.id,
                  child: _picture(main),
                  preview: _picture(main, fullSize: true),
                  actions: [
                    CascaActionMenuItem(
                      id: 'replace',
                      label: 'Cambiar foto',
                      onSelected: () =>
                          _choose(context, ref, replacing: main.id),
                    ),
                    if (!isEdit)
                      CascaActionMenuItem(
                        id: 'remove',
                        label: 'Quitar',
                        danger: true,
                        onSelected: () => controller.remove(main.id),
                      ),
                  ],
                ),
          secondary: [
            for (final slot in photos.secondary)
              CascaImageItem(
                id: slot.id,
                child: _picture(slot),
                preview: _picture(slot, fullSize: true),
                actions: [
                  CascaActionMenuItem(
                    id: 'replace',
                    label: 'Cambiar foto',
                    onSelected: () => _choose(context, ref, replacing: slot.id),
                  ),
                  if (!isEdit)
                    CascaActionMenuItem(
                      id: 'main',
                      label: 'Hacer principal',
                      onSelected: () => controller.makeMain(slot.id),
                    ),
                  CascaActionMenuItem(
                    id: 'remove',
                    label: 'Eliminar',
                    danger: true,
                    onSelected: () => controller.remove(slot.id),
                  ),
                ],
              ),
          ],
          onAdd: photos.freeSlots > 0 ? () => _choose(context, ref) : null,
          onReorder: controller.reorder,
        ),
        if (error != null) ...[
          const SizedBox(height: CascaSpacing.space2),
          Text(
            apiErrorMessage(
              error,
              'No fue posible procesar la imagen.',
              forbidden: 'No tienes permiso para cambiar las imágenes.',
            ),
            style: textTheme.bodySmall?.copyWith(color: colors.danger),
          ),
        ],
      ],
    );
  }
}
