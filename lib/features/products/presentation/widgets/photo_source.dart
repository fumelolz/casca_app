import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/features/products/data/photo_picker.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _PhotoSource { camera, gallery }

Future<List<PickedPhoto>> pickPhotos(
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
