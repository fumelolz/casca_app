import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/features/cash_registers/data/models/cash_register_model.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/cash_register_list_provider.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/cash_register_delete_modal.dart';
import 'package:casca_app/features/cash_registers/presentation/widgets/cash_register_form_modal.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_filter_bar.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

final _columns = <CascaTableColumn<CashRegisterModel>>[
  CascaTableColumn(
    id: 'name',
    header: 'Nombre',
    flex: 3,
    sortable: true,
    showOnCompact: true,
    cellBuilder: (context, register) => Text(
      register.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ),
  CascaTableColumn(
    id: 'description',
    header: 'Descripción',
    flex: 4,
    cellBuilder: (context, register) => Text(
      register.description ?? '—',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ),
  CascaTableColumn(
    id: 'status',
    header: 'Estado',
    flex: 2,
    showOnCompact: true,
    cellBuilder: (context, register) => CascaStatusChip(
      label: register.isOpen ? 'Abierta' : 'Cerrada',
      tone: register.isOpen ? CascaChipTone.success : CascaChipTone.neutral,
    ),
  ),
];

void _openForm(BuildContext context, {CashRegisterModel? cashRegister}) {
  showCascaModal<void>(
    context: context,
    builder: (_) => CashRegisterFormModal(cashRegister: cashRegister),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  CashRegisterModel cashRegister,
) async {
  final query = ref.read(cashRegisterListQueryProvider.notifier);
  final currentPage = ref.read(cashRegisterListQueryProvider).page;
  final wasLastOfPage =
      ref.read(cashRegisterListProvider).value?.items.length == 1;
  final deleted = await showCascaModal<bool>(
    context: context,
    size: CascaModalSize.sm,
    builder: (_) => CashRegisterDeleteModal(cashRegister: cashRegister),
  );
  if (!context.mounted) return;
  if (deleted == true && wasLastOfPage && currentPage > 1) {
    query.setPage(currentPage - 1);
  }
}

class CashRegisterListPage extends ConsumerWidget {
  const CashRegisterListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(cashRegisterListQueryProvider);
    final queryController = ref.read(cashRegisterListQueryProvider.notifier);
    final registers = ref.watch(cashRegisterListProvider);
    final page = registers.value;
    final failed = registers.hasError && page == null;
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final canCreate = session?.hasPermission('cashregister.create') ?? false;
    final canUpdate = session?.hasPermission('cashregister.update') ?? false;
    final canDelete = session?.hasPermission('cashregister.delete') ?? false;
    final filtered =
        query.search.isNotEmpty || query.status != CashRegisterStatusFilter.all;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CascaPageHeader(
            title: 'Cajas registradoras',
            subtitle: 'Administra las cajas de tu sucursal.',
            action: canCreate
                ? CascaButton(
                    label: 'Agregar caja',
                    onPressed: () => _openForm(context),
                  )
                : null,
          ),
          const SizedBox(height: CascaSpacing.space5),
          CascaFilterBar(
            searchHint: 'Buscar caja...',
            onSearchChanged: queryController.setSearch,
            filter: CascaSelect<CashRegisterStatusFilter>(
              options: [
                for (final filter in CashRegisterStatusFilter.values)
                  CascaSelectOption(value: filter, label: filter.label),
              ],
              value: query.status,
              onChanged: queryController.setStatus,
            ),
          ),
          const SizedBox(height: CascaSpacing.space4),
          CascaTable<CashRegisterModel>(
            columns: _columns,
            rows: page?.items ?? const [],
            rowKey: (register) => register.id,
            loading: registers.isLoading,
            errorMessage: failed
                ? 'No fue posible obtener las cajas registradoras.'
                : null,
            onRetry: () => ref.invalidate(cashRegisterListProvider),
            emptyTitle: filtered
                ? 'No se encontraron cajas.'
                : 'Aún no hay cajas registradoras.',
            rowActions: [
              if (canUpdate)
                CascaTableRowAction(
                  label: 'Editar',
                  icon: CascaIcons.pencilSimple,
                  onSelected: (register) =>
                      _openForm(context, cashRegister: register),
                ),
              if (canDelete)
                CascaTableRowAction(
                  label: 'Eliminar',
                  icon: CascaIcons.trash,
                  danger: true,
                  onSelected: (register) =>
                      _confirmDelete(context, ref, register),
                ),
            ],
            sort: CascaTableSort(
              'name',
              query.descending
                  ? CascaSortDirection.desc
                  : CascaSortDirection.asc,
            ),
            onSortChanged: (sort) => queryController.setDescending(
              sort?.direction == CascaSortDirection.desc,
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
