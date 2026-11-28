import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/shared/ui/casca_remote_image.dart';
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
          child: ProductPicture(image: image),
        ),
      ),
    );
  }
}

class ProductPicture extends StatelessWidget {
  const ProductPicture({
    super.key,
    this.image,
    this.fullSize = false,
    this.fit,
  });

  final ProductImageModel? image;
  final bool fullSize;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final paths = fullSize ? image?.fullSizePaths : image?.paths;
    return CascaRemoteImage(
      paths: paths ?? const [],
      fit: fit ?? (fullSize ? BoxFit.contain : BoxFit.cover),
    );
  }
}
