import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/domain/cart_rules.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_remote_image.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:material_ui/material_ui.dart';

const double _targetCardWidth = 180;
const double _detailsHeight = 84;
const double _unavailableOpacity = 0.5;
const int _skeletonCount = 8;

class PosProductGrid extends StatelessWidget {
  const PosProductGrid({
    super.key,
    required this.items,
    required this.loading,
    required this.hasNextPage,
    required this.quantityOf,
    required this.onAdd,
    required this.onLoadMore,
  });

  final List<PosCatalogItemModel> items;
  final bool loading;
  final bool hasNextPage;
  final double Function(PosCatalogItemModel item) quantityOf;
  final ValueChanged<PosCatalogItemModel> onAdd;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final showSkeleton = loading && items.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _targetCardWidth).floor().clamp(
          2,
          8,
        );
        final cardWidth =
            (constraints.maxWidth - CascaSpacing.space3 * (columns - 1)) /
            columns;

        return CustomScrollView(
          slivers: [
            SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: CascaSpacing.space3,
                mainAxisSpacing: CascaSpacing.space3,
                mainAxisExtent: cardWidth + _detailsHeight,
              ),
              itemCount: showSkeleton ? _skeletonCount : items.length,
              itemBuilder: (context, index) {
                if (showSkeleton) {
                  return const CascaSkeleton(
                    height: double.infinity,
                    borderRadius: CascaRadius.md,
                  );
                }
                final item = items[index];
                return _ProductCard(
                  key: ValueKey('pos-item-${item.id}'),
                  item: item,
                  quantity: quantityOf(item),
                  onTap: isAvailable(item) ? () => onAdd(item) : null,
                );
              },
            ),
            if (hasNextPage && !showSkeleton)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(CascaSpacing.space4),
                  child: Center(
                    child: CascaButton(
                      label: 'Cargar más',
                      variant: CascaButtonVariant.secondary,
                      loading: loading,
                      onPressed: onLoadMore,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onTap,
  });

  final PosCatalogItemModel item;
  final double quantity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final available = onTap != null;
    final selected = quantity > 0;

    return Semantics(
      button: true,
      enabled: available,
      label:
          '${item.displayName}, ${formatMoney(item.price)}'
          '${available ? '' : ', agotado'}',
      excludeSemantics: true,
      child: Opacity(
        opacity: available ? 1 : _unavailableOpacity,
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: CascaRadius.md,
            side: BorderSide(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: colors.backgroundHover,
                        child: CascaRemoteImage(
                          paths: item.imagePaths,
                          iconSize: CascaSpacing.space7,
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: CascaSpacing.space2,
                          right: CascaSpacing.space2,
                          child: _Badge(formatQuantity(quantity)),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: _detailsHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(CascaSpacing.space3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          available ? formatMoney(item.price) : 'Agotado',
                          maxLines: 1,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: CascaFontWeight.semibold,
                            color: available ? null : colors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Container(
      constraints: const BoxConstraints(minWidth: CascaSpacing.space6),
      padding: const EdgeInsets.symmetric(
        horizontal: CascaSpacing.space2,
        vertical: CascaSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: CascaRadius.lg,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.onPrimary,
          fontWeight: CascaFontWeight.semibold,
        ),
      ),
    );
  }
}
