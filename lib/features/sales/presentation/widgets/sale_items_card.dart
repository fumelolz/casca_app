import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/sales/data/models/sale_history_model.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_remote_image.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:material_ui/material_ui.dart';

const double _imageSize = 48;
const double _compactAmountWidth = 112;
const int _quantityFlex = 2;
const int _descriptionFlex = 6;
const int _moneyFlex = 2;
const String _missingSku = 'SKU: —';

CascaTableColumn<SaleLineModel> _amountColumn({int flex = 1, double? width}) {
  return CascaTableColumn(
    id: 'amount',
    header: 'Importe',
    flex: flex,
    width: width,
    align: CascaTableAlign.end,
    showOnCompact: true,
    cellBuilder: (context, item) => Text(
      formatMoney(item.total),
      style: Theme.of(context).textTheme.titleSmall,
    ),
  );
}

final _wideColumns = <CascaTableColumn<SaleLineModel>>[
  CascaTableColumn(
    id: 'quantity',
    header: 'Cant.',
    flex: _quantityFlex,
    cellBuilder: (context, item) => CascaTableTwoLineCell(
      title: formatQuantity(item.quantity),
      subtitle: item.unitName,
    ),
  ),
  CascaTableColumn(
    id: 'description',
    header: 'Descripción',
    flex: _descriptionFlex,
    cellBuilder: (context, item) => _Product(item.name),
  ),
  CascaTableColumn(
    id: 'price',
    header: 'Precio',
    flex: _moneyFlex,
    align: CascaTableAlign.end,
    cellBuilder: (context, item) => Text(
      formatMoney(item.unitPrice),
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ),
  _amountColumn(flex: _moneyFlex),
];

final _compactColumns = <CascaTableColumn<SaleLineModel>>[
  CascaTableColumn(
    id: 'description',
    header: 'Descripción',
    showOnCompact: true,
    cellBuilder: (context, item) => _Product(
      item.name,
      detail:
          '${formatQuantity(item.quantity)} ${item.unitName} × '
          '${formatMoney(item.unitPrice)}',
    ),
  ),
  _amountColumn(width: _compactAmountWidth),
];

class SaleItemsCard extends StatelessWidget {
  const SaleItemsCard({super.key, required this.sale});

  final SaleDetailModel sale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space3,
      children: [
        Text(
          'Productos vendidos (${sale.items.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        LayoutBuilder(
          builder: (context, constraints) => CascaTable<SaleLineModel>(
            columns: constraints.maxWidth >= cascaTableCompactBreakpoint
                ? _wideColumns
                : _compactColumns,
            rows: sale.items,
            rowKey: (item) => item.id,
            emptyTitle: 'La venta no tiene productos.',
          ),
        ),
        Column(
          children: [
            _TotalRow('Subtotal', sale.subtotal),
            _TotalRow('Total', sale.total, strong: true),
          ],
        ),
      ],
    );
  }
}

class _Product extends StatelessWidget {
  const _Product(this.name, {this.detail});

  final String name;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: colors.textSecondary);
    final detail = this.detail;

    return Row(
      spacing: CascaSpacing.space3,
      children: [
        Semantics(
          label: 'Sin foto',
          child: Container(
            width: _imageSize,
            height: _imageSize,
            decoration: BoxDecoration(
              color: colors.surfaceHover,
              borderRadius: CascaRadius.md,
            ),
            child: const CascaRemoteImage(paths: []),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CascaSpacing.space1,
            children: [
              Text(name, style: textTheme.bodyMedium),
              Text(_missingSku, style: muted),
              if (detail != null) Text(detail, style: muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.amount, {this.strong = false});

  final String label;
  final double amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = strong ? textTheme.titleMedium : textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(
        top: CascaSpacing.space1,
        right: CascaSpacing.space4 + CascaSpacing.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: CascaSpacing.space6,
        children: [
          Text(label, style: style),
          Text(formatMoney(amount), style: style),
        ],
      ),
    );
  }
}
