import 'package:casca_app/app/theme/casca_colors.dart';
import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/data/models/inventory_movement_model.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/data/models/product_list_item_model.dart';
import 'package:casca_app/features/products/data/models/product_variant_model.dart';
import 'package:casca_app/features/products/domain/inventory_movement_rules.dart';
import 'package:casca_app/features/products/domain/product_detail_rules.dart';
import 'package:casca_app/features/products/domain/product_list_rules.dart';
import 'package:casca_app/features/products/domain/product_variant_view_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_detail_providers.dart';
import 'package:casca_app/features/products/presentation/widgets/product_gallery.dart';
import 'package:casca_app/features/products/presentation/widgets/product_thumbnail.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_action_menu.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _heroWideWidth = 600;
const double _heroImageWidth = 260;
const double _phoneImageWidth = 260;
const double _tableWideWidth = 640;
const double _variantImageSize = 40;
const double _actionSize = 44;
const int _skeletonRows = 3;

(Color, Color) _toneColors(CascaColors colors, StockTone tone) => switch (tone) {
  StockTone.good => (colors.success, colors.successSoft),
  StockTone.warning => (colors.warning, colors.warningSoft),
  StockTone.danger => (colors.danger, colors.dangerSoft),
};

class ProductHero extends StatelessWidget {
  const ProductHero({
    super.key,
    required this.product,
    required this.images,
    required this.showTaxes,
  });

  final ProductDetailModel product;
  final List<ProductImageModel> images;
  final bool showTaxes;

  @override
  Widget build(BuildContext context) {
    return CascaCard(
      padding: const EdgeInsets.all(CascaSpacing.space6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final info = _HeroInfo(product: product, showTaxes: showTaxes);
          if (constraints.maxWidth < _heroWideWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: CascaSpacing.space5,
              children: [
                Center(
                  child: SizedBox(
                    width: _phoneImageWidth,
                    child: ProductGallery(images: images),
                  ),
                ),
                info,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CascaSpacing.space6,
            children: [
              Expanded(child: info),
              SizedBox(
                width: _heroImageWidth,
                child: ProductGallery(images: images),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroInfo extends StatelessWidget {
  const _HeroInfo({required this.product, required this.showTaxes});

  final ProductDetailModel product;
  final bool showTaxes;

  List<Widget> _stats(CascaColors colors) {
    final range = priceRange(product);
    final isRange = range != null && range.min != range.max;
    final tax = showTaxes ? ivaLabel(product.ivaRate) : null;
    final price = _Stat(
      isRange ? 'Precio desde' : 'Precio',
      range == null ? '—' : formatMoney(range.min),
      caption: isRange ? 'hasta ${formatMoney(range.max)}' : tax,
    );
    if (product.isService) return [price];

    final stock = totalStock(product);
    if (product.hasVariants) {
      final count = product.variants.length;
      return [
        price,
        _Stat('Existencias', formatQuantity(stock), caption: 'Unidades'),
        _Stat(
          'Variantes',
          '$count',
          caption:
              '${product.variants.where(isVariantActive).length} activas',
        ),
      ];
    }

    final level = stockLevel(
      stock,
      product.minimumStock ?? 0,
      product.maximumStock,
    );
    final cost = product.averageCost ?? 0;
    final margin = profitMargin(range?.min ?? 0, cost);
    return [
      price,
      _Stat('Costo promedio', formatMoney(cost)),
      _Stat(
        'Existencias',
        formatQuantity(stock),
        caption: level.status.label,
        captionColor: _toneColors(colors, stockTone(level.status)).$1,
      ),
      if (margin != null)
        _Stat(
          'Ganancia',
          '${margin.amount < 0 ? '-' : ''}${formatMoney(margin.amount.abs())}',
          caption: margin.percentage == null
              ? null
              : 'Margen ${margin.percentage}%',
          captionColor: switch (margin.tone) {
            ProfitTone.positive => colors.success,
            ProfitTone.negative => colors.danger,
            ProfitTone.neutral => null,
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final barcode = product.hasVariants ? null : product.baseUnit?.barcode;
    final codes = [
      if (product.sku.isNotEmpty) 'SKU ${product.sku}',
      if (barcode != null && barcode.isNotEmpty) 'Cód. de barras $barcode',
    ].join('   ·   ');
    final category = product.categoryName;
    final description = product.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: CascaSpacing.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (category != null) Text('Categoría $category', style: muted),
            if (product.isService)
              const CascaStatusChip(label: 'Servicio', tone: CascaChipTone.info),
            if (!product.isActive)
              const CascaStatusChip(
                label: 'Inactivo',
                tone: CascaChipTone.neutral,
              ),
          ],
        ),
        const SizedBox(height: CascaSpacing.space1),
        Text(product.name, style: textTheme.headlineMedium),
        if (codes.isNotEmpty) ...[
          const SizedBox(height: CascaSpacing.space1),
          Text(codes, style: muted),
        ],
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: CascaSpacing.space2),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        ],
        const SizedBox(height: CascaSpacing.space6),
        Wrap(
          spacing: CascaSpacing.space7,
          runSpacing: CascaSpacing.space4,
          children: _stats(colors),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.caption, this.captionColor});

  final String label;
  final String value;
  final String? caption;
  final Color? captionColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final caption = this.caption;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        Text(value, style: textTheme.headlineMedium),
        if (caption != null)
          Text(
            caption,
            style: textTheme.bodySmall?.copyWith(
              color: captionColor ?? colors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _Column {
  const _Column(this.label, this.flex, {this.end = false});

  final String label;
  final int flex;
  final bool end;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.columns, this.trailing = 0});

  final List<_Column> columns;
  final double trailing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: context.casca.textSecondary,
      fontWeight: CascaFontWeight.semibold,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: CascaSpacing.space3),
      child: Row(
        spacing: CascaSpacing.space3,
        children: [
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Text(
                column.label,
                textAlign: column.end ? TextAlign.end : TextAlign.start,
                style: style,
              ),
            ),
          if (trailing > 0) SizedBox(width: trailing),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space3),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.casca.border)),
      ),
      child: child,
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.stock, required this.tone});

  final double stock;
  final StockTone tone;

  @override
  Widget build(BuildContext context) {
    final (color, background) = _toneColors(context.casca, tone);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CascaSpacing.space2,
        vertical: CascaSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: CascaRadius.sm,
      ),
      child: Text(
        formatQuantity(stock),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: CascaFontWeight.semibold,
        ),
      ),
    );
  }
}

class ProductVariantsCard extends StatelessWidget {
  const ProductVariantsCard({
    super.key,
    required this.product,
    required this.onAdjust,
  });

  final ProductDetailModel product;
  final ValueChanged<ProductVariantModel>? onAdjust;

  static const _columns = [
    _Column('Variante', 5),
    _Column('Precio', 2, end: true),
    _Column('Mínimo', 2, end: true),
    _Column('Existencias', 2, end: true),
  ];

  @override
  Widget build(BuildContext context) {
    final variants = sortVariants(product.variants);
    final trailing = onAdjust == null ? 0.0 : _actionSize;

    return CascaCard(
      title: 'Variantes',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _tableWideWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) _TableHeader(columns: _columns, trailing: trailing),
              for (final variant in variants)
                _TableRow(
                  child: _VariantRow(
                    variant: variant,
                    product: product,
                    wide: wide,
                    onAdjust: onAdjust,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
    required this.product,
    required this.wide,
    required this.onAdjust,
  });

  final ProductVariantModel variant;
  final ProductDetailModel product;
  final bool wide;
  final ValueChanged<ProductVariantModel>? onAdjust;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final price = variant.saleUnit?.price;
    final priceText = price == null ? '—' : formatMoney(price);
    final adjust = onAdjust;
    final level = stockLevel(
      variant.stock,
      variant.minimumStock,
      variant.maximumStock,
    );
    final pill = Align(
      alignment: Alignment.centerRight,
      child: _StockPill(stock: variant.stock, tone: stockTone(level.status)),
    );
    final details = [
      if (!wide) priceText,
      if (variant.sku.isNotEmpty) variant.sku,
      if (!isVariantActive(variant)) variantStatusLabel(variant.status),
    ].join('  ·  ');

    final name = Row(
      spacing: CascaSpacing.space3,
      children: [
        ClipRRect(
          borderRadius: CascaRadius.sm,
          child: SizedBox.square(
            dimension: _variantImageSize,
            child: ColoredBox(
              color: colors.backgroundHover,
              child: ProductPicture(image: variant.image ?? product.image),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                variantName(variant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: CascaFontWeight.medium,
                ),
              ),
              if (details.isNotEmpty)
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
            ],
          ),
        ),
      ],
    );

    return Row(
      spacing: CascaSpacing.space3,
      children: [
        if (wide) ...[
          Expanded(flex: 5, child: name),
          Expanded(
            flex: 2,
            child: Text(
              priceText,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatQuantity(variant.minimumStock),
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(flex: 2, child: pill),
        ] else ...[
          Expanded(child: name),
          pill,
        ],
        if (adjust != null)
          CascaActionMenu(
            semanticLabel: 'Acciones de ${variantName(variant)}',
            sections: [
              CascaActionMenuSection(
                items: [
                  CascaActionMenuItem(
                    id: 'adjust',
                    label: 'Ajustar existencias',
                    icon: CascaIcons.arrowsDownUp,
                    onSelected: () => adjust(variant),
                  ),
                ],
              ),
            ],
            child: SizedBox.square(
              dimension: _actionSize,
              child: Center(
                child: CascaIcon(
                  CascaIcons.dotsThreeVertical,
                  size: CascaSpacing.space5,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProductPricesCard extends StatelessWidget {
  const ProductPricesCard({super.key, required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return CascaCard(
      title: 'Unidades de venta',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final unit in product.saleUnits)
            _TableRow(
              child: Row(
                spacing: CascaSpacing.space2,
                children: [
                  Expanded(
                    child: Text(
                      unit.barcode?.isNotEmpty ?? false
                          ? unit.barcode!
                          : 'Sin código de barras',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  if (unit.isInventoryBaseUnit)
                    const CascaStatusChip(
                      label: 'Base',
                      tone: CascaChipTone.info,
                    ),
                  Text(formatMoney(unit.price), style: textTheme.bodyMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ProductMovementsCard extends ConsumerWidget {
  const ProductMovementsCard({super.key, required this.product});

  final ProductDetailModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productMovementsProvider(product.id));
    final controller = ref.read(
      productMovementsProvider(product.id).notifier,
    );
    final textTheme = Theme.of(context).textTheme;
    final error = state.error;
    final firstLoad = state.loading && state.items.isEmpty;
    final stockAfter = product.hasVariants
        ? null
        : stockAfterEachMovement(state.items, product.stock ?? 0);
    final columns = [
      const _Column('Fecha', 3),
      const _Column('Movimiento', 4),
      const _Column('Tipo', 2),
      const _Column('Cantidad', 2, end: true),
      if (stockAfter != null) const _Column('Nuevo stock', 2, end: true),
    ];

    return CascaCard(
      title: 'Últimos movimientos',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _tableWideWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (firstLoad)
                for (var i = 0; i < _skeletonRows; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: CascaSpacing.space3),
                    child: CascaSkeleton(height: CascaSpacing.space7),
                  )
              else if (state.items.isEmpty && error == null)
                Text(
                  'Todavía no hay movimientos de inventario.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.casca.textSecondary,
                  ),
                )
              else if (wide && state.items.isNotEmpty)
                _TableHeader(columns: columns),
              for (final (index, movement) in state.items.indexed)
                _TableRow(
                  child: _MovementRow(
                    movement: movement,
                    columns: columns,
                    wide: wide,
                    stockAfter: stockAfter?[index],
                    subject: product.hasVariants
                        ? movementSubject(movement.displayName, product.name)
                        : null,
                  ),
                ),
              if (error != null && !state.loading) ...[
                const SizedBox(height: CascaSpacing.space3),
                Text(
                  apiErrorMessage(
                    error,
                    'No fue posible obtener los movimientos.',
                    forbidden: 'No tienes permiso para ver el inventario.',
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.casca.danger,
                  ),
                ),
                const SizedBox(height: CascaSpacing.space3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CascaButton(
                    label: 'Reintentar',
                    variant: CascaButtonVariant.secondary,
                    onPressed: state.items.isEmpty
                        ? controller.reload
                        : controller.loadMore,
                  ),
                ),
              ] else if (state.hasNextPage) ...[
                const SizedBox(height: CascaSpacing.space3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: CascaButton(
                    label: 'Ver más movimientos',
                    variant: CascaButtonVariant.secondary,
                    loading: state.loading,
                    onPressed: controller.loadMore,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({
    required this.movement,
    required this.columns,
    required this.wide,
    required this.stockAfter,
    required this.subject,
  });

  final InventoryMovementModel movement;
  final List<_Column> columns;
  final bool wide;
  final double? stockAfter;
  final String? subject;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final quantity = movement.quantity;
    final entry = quantity >= 0;
    final reason = movement.reason == null
        ? movementTypeLabel(movement.movementType)
        : movementReasonLabel(movement.reason);
    final subject = this.subject;
    final stockAfter = this.stockAfter;
    final date = formatDateTime(movement.createdAt);
    final amount = Text(
      '${quantity > 0 ? '+' : ''}${formatQuantity(quantity)}',
      textAlign: TextAlign.end,
      style: textTheme.bodyMedium?.copyWith(
        color: entry ? colors.success : colors.danger,
        fontWeight: CascaFontWeight.semibold,
      ),
    );
    final type = CascaStatusChip(
      label: entry ? 'Entrada' : 'Salida',
      tone: entry ? CascaChipTone.success : CascaChipTone.danger,
    );
    final title = Text.rich(
      TextSpan(
        text: reason,
        children: [
          if (subject != null && subject.isNotEmpty)
            TextSpan(text: '  ·  $subject', style: muted),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: textTheme.bodyMedium,
    );

    if (!wide) {
      return Row(
        spacing: CascaSpacing.space3,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CascaSpacing.space1,
              children: [title, Text(date, style: muted)],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: CascaSpacing.space1,
            children: [
              amount,
              if (stockAfter != null)
                Text('Quedan ${formatQuantity(stockAfter)}', style: muted)
              else
                type,
            ],
          ),
        ],
      );
    }

    final cells = <Widget>[
      Text(date, style: muted),
      title,
      Align(alignment: Alignment.centerLeft, child: type),
      amount,
      if (stockAfter != null)
        Text(
          formatQuantity(stockAfter),
          textAlign: TextAlign.end,
          style: textTheme.bodyMedium,
        ),
    ];
    return Row(
      spacing: CascaSpacing.space3,
      children: [
        for (final (index, cell) in cells.indexed)
          Expanded(flex: columns[index].flex, child: cell),
      ],
    );
  }
}
