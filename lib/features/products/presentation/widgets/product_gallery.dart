import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/features/products/presentation/widgets/product_thumbnail.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

const double _thumbnailSize = 56;
const double _selectedBorder = 2;
const double _placeholderIconSize = 48;
const double _emptyAspectRatio = 16 / 9;

class ProductGallery extends StatefulWidget {
  const ProductGallery({super.key, required this.images});

  final List<ProductImageModel> images;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final images = widget.images;
    final selected = _selected < images.length ? _selected : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space3,
      children: [
        AspectRatio(
          aspectRatio: images.isEmpty ? _emptyAspectRatio : 1,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.backgroundHover,
              borderRadius: CascaRadius.lg,
              border: Border.all(color: colors.border),
            ),
            child: images.isEmpty
                ? Center(
                    child: CascaIcon(
                      CascaIcons.cube,
                      size: _placeholderIconSize,
                      color: colors.textMuted,
                    ),
                  )
                : ProductPicture(
                    key: ValueKey(selected),
                    image: images[selected],
                    fullSize: true,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (images.length > 1)
          SizedBox(
            height: _thumbnailSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: CascaSpacing.space2),
              itemBuilder: (context, index) => Semantics(
                button: true,
                selected: index == selected,
                label: 'Ver imagen ${index + 1}',
                child: GestureDetector(
                  onTap: () => setState(() => _selected = index),
                  child: Container(
                    width: _thumbnailSize,
                    decoration: BoxDecoration(
                      borderRadius: CascaRadius.md,
                      border: Border.all(
                        width: _selectedBorder,
                        color: index == selected
                            ? colors.text
                            : colors.border,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: CascaRadius.sm,
                      child: ColoredBox(
                        color: colors.backgroundHover,
                        child: ProductPicture(image: images[index]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
