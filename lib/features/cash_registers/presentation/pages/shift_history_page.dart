import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/cash_registers/data/models/shift_model.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/shift_providers.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/shift_amounts.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _wideBreakpoint = 900;
const String _emptyValue = '—';

CascaTableColumn<ShiftListItemModel> _text(
  String id,
  String header,
  String Function(ShiftListItemModel shift) value, {
  CascaTableAlign align = CascaTableAlign.start,
}) {
  return CascaTableColumn(
    id: id,
    header: header,
    flex: 2,
    align: align,
    cellBuilder: (context, shift) =>
        Text(value(shift), style: Theme.of(context).textTheme.bodyMedium),
  );
}

CascaStatusChip _status(ShiftListItemModel shift) {
  return CascaStatusChip(
    label: shift.isClosed ? 'Cerrado' : 'Abierto',
    tone: shift.isClosed ? CascaChipTone.neutral : CascaChipTone.success,
  );
}

final _wideColumns = <CascaTableColumn<ShiftListItemModel>>[
  CascaTableColumn(
    id: 'register',
    header: 'Caja',
    flex: 3,
    showOnCompact: true,
    cellBuilder: (context, shift) => CascaTableTwoLineCell(
      title: shift.cashRegisterName,
      subtitle: shift.userName,
    ),
  ),
  CascaTableColumn(
    id: 'status',
    header: 'Estado',
    flex: 2,
    cellBuilder: (context, shift) => _status(shift),
  ),
  _text('opened', 'Apertura', (shift) => formatDateTime(shift.openedAt)),
  _text('closed', 'Cierre', (shift) {
    final closedAt = shift.closedAt;
    return closedAt == null ? _emptyValue : formatDateTime(closedAt);
  }),
  _text(
    'initial',
    'Monto inicial',
    (shift) => formatMoney(shift.initialAmount),
    align: CascaTableAlign.end,
  ),
  _text(
    'sales',
    'Ventas',
    (shift) => formatMoney(shift.totalSales),
    align: CascaTableAlign.end,
  ),
  CascaTableColumn(
    id: 'difference',
    header: 'Diferencia',
    flex: 2,
    align: CascaTableAlign.end,
    cellBuilder: (context, shift) => ShiftDifference(shift.difference),
  ),
];

final _compactColumns = <CascaTableColumn<ShiftListItemModel>>[
  CascaTableColumn(
    id: 'register',
    header: 'Turno',
    flex: 3,
    showOnCompact: true,
    cellBuilder: (context, shift) => Padding(
      padding: const EdgeInsets.symmetric(vertical: CascaSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: CascaSpacing.space1,
        children: [
          CascaTableTwoLineCell(
            title: shift.cashRegisterName,
            subtitle: shift.userName,
          ),
          Text(
            formatDateTime(shift.openedAt),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.casca.textSecondary),
          ),
        ],
      ),
    ),
  ),
  CascaTableColumn(
    id: 'summary',
    header: 'Ventas',
    flex: 2,
    align: CascaTableAlign.end,
    showOnCompact: true,
    cellBuilder: (context, shift) => Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      spacing: CascaSpacing.space1,
      children: [
        Text(
          formatMoney(shift.totalSales),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        _status(shift),
        if (shift.difference != null) ShiftDifference(shift.difference),
      ],
    ),
  ),
];

class ShiftHistoryPage extends ConsumerWidget {
  const ShiftHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shifts = ref.watch(shiftListProvider);
    final page = shifts.value;
    final error = shifts.error;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space5,
        children: [
          const CascaPageHeader(
            title: 'Historial de turnos',
            subtitle: 'Consulta las aperturas y cortes de tus cajas.',
          ),
          LayoutBuilder(
            builder: (context, constraints) => CascaTable<ShiftListItemModel>(
              columns: constraints.maxWidth >= _wideBreakpoint
                  ? _wideColumns
                  : _compactColumns,
              rows: page?.items ?? const [],
              rowKey: (shift) => shift.id,
              loading: shifts.isLoading,
              errorMessage: error == null || shifts.isLoading
                  ? null
                  : apiErrorMessage(
                      error,
                      'No fue posible obtener el historial de turnos.',
                      forbidden: 'No tienes permiso para ver los turnos.',
                    ),
              onRetry: () => ref.invalidate(shiftListProvider),
              emptyTitle: 'Aún no hay turnos.',
              onRowTap: (shift) =>
                  context.go(AppRoutes.shiftDetailFor(shift.id)),
              page: ref.watch(shiftListPageProvider),
              pageSize: shiftPageSize,
              totalItems: page?.totalCount,
              onPageChanged: ref.read(shiftListPageProvider.notifier).setPage,
            ),
          ),
        ],
      ),
    );
  }
}
