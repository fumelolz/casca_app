import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/sales/data/models/sale_history_model.dart';
import 'package:casca_app/features/sales/data/sales_repository.dart';
import 'package:casca_app/features/sales/domain/sale_labels.dart';
import 'package:casca_app/features/sales/presentation/providers/sales_providers.dart';
import 'package:casca_app/features/sales/presentation/widgets/sale_status_chip.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

String _created(SaleListItemModel sale) {
  final date = sale.createdAt;
  return date == null ? '—' : formatDateTime(date);
}

CascaTableColumn<SaleListItemModel> _text(
  String id,
  String header,
  String Function(SaleListItemModel sale) value, {
  bool sortable = false,
  bool showOnCompact = false,
  CascaTableAlign align = CascaTableAlign.start,
}) {
  return CascaTableColumn(
    id: id,
    header: header,
    flex: 2,
    align: align,
    sortable: sortable,
    showOnCompact: showOnCompact,
    cellBuilder: (context, sale) =>
        Text(value(sale), style: Theme.of(context).textTheme.bodyMedium),
  );
}

final _wideColumns = <CascaTableColumn<SaleListItemModel>>[
  _text(
    SaleSortField.saleNumber.name,
    'Venta',
    (sale) => sale.saleNumber,
    sortable: true,
    showOnCompact: true,
  ),
  CascaTableColumn(
    id: SaleSortField.status.name,
    header: 'Estado',
    flex: 2,
    sortable: true,
    cellBuilder: (context, sale) => SaleStatusChip(sale.status),
  ),
  _text(
    SaleSortField.paymentMethod.name,
    'Método de pago',
    (sale) => salePaymentsLabel(sale.payments),
    sortable: true,
  ),
  _text(
    'total',
    'Total',
    (sale) => formatMoney(sale.total),
    align: CascaTableAlign.end,
  ),
  _text(SaleSortField.created.name, 'Fecha', _created, sortable: true),
];

final _compactColumns = <CascaTableColumn<SaleListItemModel>>[
  CascaTableColumn(
    id: SaleSortField.saleNumber.name,
    header: 'Venta',
    flex: 3,
    sortable: true,
    showOnCompact: true,
    cellBuilder: (context, sale) => Padding(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CascaTableTwoLineCell(
            title: sale.saleNumber,
            subtitle: _created(sale),
          ),
          Text(
            salePaymentsLabel(sale.payments),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  ),
  CascaTableColumn(
    id: 'total',
    header: 'Total',
    flex: 2,
    align: CascaTableAlign.end,
    showOnCompact: true,
    cellBuilder: (context, sale) => Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      spacing: CascaSpacing.space1,
      children: [
        Text(
          formatMoney(sale.total),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (sale.status == cancelledSaleStatus) SaleStatusChip(sale.status),
      ],
    ),
  ),
];

class SalesHistoryPage extends ConsumerStatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  ConsumerState<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends ConsumerState<SalesHistoryPage> {
  late final _search = TextEditingController(
    text: ref.read(salesQueryProvider).search,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _sort(CascaTableSort? sort) {
    final controller = ref.read(salesQueryProvider.notifier);
    if (sort == null) {
      controller.setSort(null);
      return;
    }
    controller.setSort(
      SaleSortField.values.byName(sort.columnId),
      descending: sort.direction == CascaSortDirection.desc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(salesQueryProvider);
    final sales = ref.watch(salesListProvider);
    final page = sales.value;
    final error = sales.error;
    final sort = query.sort;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          const CascaPageHeader(
            title: 'Ventas realizadas',
            subtitle: 'Consulta las ventas de tu tienda y su detalle.',
          ),
          CascaInput(
            controller: _search,
            hintText: 'Buscar número de venta exacto',
            iconStart: CascaIcons.magnifyingGlass,
            clearable: true,
            textInputAction: TextInputAction.search,
            onChanged: ref.read(salesQueryProvider.notifier).setSearch,
          ),
          LayoutBuilder(
            builder: (context, constraints) => CascaTable<SaleListItemModel>(
              columns: constraints.maxWidth >= cascaTableCompactBreakpoint
                  ? _wideColumns
                  : _compactColumns,
              rows: page?.items ?? const [],
              rowKey: (sale) => sale.id,
              loading: sales.isLoading,
              errorMessage: error == null || sales.isLoading
                  ? null
                  : apiErrorMessage(
                      error,
                      'No fue posible cargar el historial de ventas.',
                      forbidden: 'No tienes permiso para ver las ventas.',
                    ),
              onRetry: () => ref.invalidate(salesListProvider),
              emptyTitle: query.search.isEmpty
                  ? 'No hay ventas para mostrar.'
                  : 'No hay una venta con ese número.',
              sort: sort == null
                  ? null
                  : CascaTableSort(
                      sort.name,
                      query.descending
                          ? CascaSortDirection.desc
                          : CascaSortDirection.asc,
                    ),
              onSortChanged: _sort,
              onRowTap: (sale) => context.go(AppRoutes.saleDetailFor(sale.id)),
              page: query.page,
              pageSize: salesPageSize,
              totalItems: page?.totalCount,
              onPageChanged: ref.read(salesQueryProvider.notifier).setPage,
            ),
          ),
        ],
      ),
    );
  }
}
