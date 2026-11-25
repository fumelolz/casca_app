import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/features/products/data/product_repository.dart';
import 'package:casca_app/features/products/domain/product_list_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/product_thumbnail.dart';
import 'package:casca_app/features/products/presentation/widgets/stock_level_indicator.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_filter_bar.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const String _emptyValue = '—';

final _columns = <CascaTableColumn<ProductListItemModel>>[
  CascaTableColumn(
    id: ProductSortField.name.name,
    header: 'Producto',
    flex: 4,
    sortable: true,
    showOnCompact: true,
    cellBuilder: (context, product) => _NameCell(product),
  ),
  CascaTableColumn(
    id: 'price',
    header: 'Precio de venta',
    flex: 2,
    align: CascaTableAlign.end,
    cellBuilder: (context, product) => _PriceCell(product),
  ),
  CascaTableColumn(
    id: 'cost',
    header: 'Costo promedio',
    flex: 2,
    align: CascaTableAlign.end,
    cellBuilder: (context, product) => _AmountText(
      product.hasVariants ? 'Varía' : formatMoney(product.averageCost),
    ),
  ),
  CascaTableColumn(
    id: 'margin',
    header: 'Margen',
    flex: 2,
    align: CascaTableAlign.end,
    cellBuilder: (context, product) => _MarginCell(product),
  ),
  CascaTableColumn(
    id: ProductSortField.stock.name,
    header: 'Stock',
    flex: 3,
    sortable: true,
    showOnCompact: true,
    cellBuilder: (context, product) => product.isService
        ? const _AmountText(_emptyValue)
        : StockLevelIndicator(
            stock: product.stock,
            minimumStock: product.minimumStock,
            maximumStock: product.maximumStock,
          ),
  ),
];

class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(productListQueryProvider);
    final products = ref.watch(productListProvider);
    final page = products.value;
    final failed = products.hasError && page == null;
    final queryController = ref.read(productListQueryProvider.notifier);

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CascaPageHeader(
            title: 'Productos',
            subtitle: 'Consulta los productos y su inventario.',
          ),
          const SizedBox(height: CascaSpacing.space5),
          CascaFilterBar(
            searchHint: 'Buscar por nombre, SKU o código...',
            onSearchChanged: queryController.setSearch,
          ),
          const SizedBox(height: CascaSpacing.space4),
          CascaTable<ProductListItemModel>(
            columns: _columns,
            rows: page?.items ?? const [],
            rowKey: (product) => product.id,
            loading: products.isLoading,
            errorMessage: failed
                ? 'No fue posible obtener los productos.'
                : null,
            onRetry: () => ref.invalidate(productListProvider),
            emptyTitle: query.search.isEmpty
                ? 'No existen productos.'
                : 'No se encontraron productos.',
            emptyMessage: query.search.isEmpty
                ? null
                : 'Prueba con otra búsqueda.',
            sort: query.sort == ProductSortField.created
                ? null
                : CascaTableSort(
                    query.sort.name,
                    query.descending
                        ? CascaSortDirection.desc
                        : CascaSortDirection.asc,
                  ),
            onSortChanged: (sort) => sort == null
                ? queryController.resetSort()
                : queryController.setSort(
                    ProductSortField.values.byName(sort.columnId),
                    descending: sort.direction == CascaSortDirection.desc,
                  ),
            page: query.page,
            pageSize: query.pageSize,
            totalItems: page?.totalCount,
            onPageChanged: queryController.setPage,
          ),
        ],
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell(this.product);

  final ProductListItemModel product;

  @override
  Widget build(BuildContext context) {
    final variants = product.variantCount == 1
        ? '1 variante'
        : '${product.variantCount} variantes';

    return Row(
      children: [
        ProductThumbnail(image: product.image),
        const SizedBox(width: CascaSpacing.space3),
        Expanded(
          child: CascaTableTwoLineCell(
            title: product.name,
            subtitle: product.hasVariants
                ? '${product.sku} · $variants'
                : product.sku,
          ),
        ),
      ],
    );
  }
}

class _PriceCell extends StatelessWidget {
  const _PriceCell(this.product);

  final ProductListItemModel product;

  @override
  Widget build(BuildContext context) {
    final maxPrice = product.maxPrice;
    final hasRange =
        product.hasVariants && maxPrice != null && maxPrice > product.price;

    return _AmountText(
      hasRange
          ? '${formatMoney(product.price)} – ${formatMoney(maxPrice)}'
          : formatMoney(product.price),
    );
  }
}

class _MarginCell extends StatelessWidget {
  const _MarginCell(this.product);

  final ProductListItemModel product;

  @override
  Widget build(BuildContext context) {
    if (product.hasVariants) return const _AmountText('Varía');

    final margin = profitMargin(
      product.price,
      product.averageCost,
      allowZeroCost: product.isService,
    );
    if (margin == null) return const _AmountText(_emptyValue);

    final colors = context.casca;
    final sign = margin.amount < 0 ? '-' : '+';
    final percentage = margin.percentage == null
        ? ''
        : ' (${margin.percentage}%)';

    return _AmountText(
      '$sign${formatMoney(margin.amount.abs())}$percentage',
      color: switch (margin.tone) {
        ProfitTone.positive => colors.success,
        ProfitTone.negative => colors.danger,
        ProfitTone.neutral => colors.textSecondary,
      },
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.end,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
    );
  }
}
