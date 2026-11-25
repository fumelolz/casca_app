import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/config/app_config.dart';
import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

const double _thumbnailSize = CascaSpacing.space8;

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({super.key, this.image});

  final ProductImageModel? image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CascaRadius.sm,
      child: SizedBox.square(
        dimension: _thumbnailSize,
        child: ColoredBox(
          color: context.casca.backgroundHover,
          child: _candidate(context, image?.paths ?? const [], 0),
        ),
      ),
    );
  }

  Widget _candidate(BuildContext context, List<String> paths, int index) {
    if (index >= paths.length) {
      return Center(
        child: CascaIcon(
          CascaIcons.cube,
          size: CascaSpacing.space5,
          color: context.casca.textMuted,
        ),
      );
    }

    return Image.network(
      '${AppConfig.apiUrl}${paths[index]}',
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) =>
          _candidate(context, paths, index + 1),
    );
  }
}
