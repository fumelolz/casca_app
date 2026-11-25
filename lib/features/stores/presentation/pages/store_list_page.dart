import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/features/stores/data/models/store_list_item_model.dart';
import 'package:casca_app/features/stores/presentation/providers/store_list_provider.dart';
import 'package:casca_app/features/stores/presentation/widgets/store_form_modal.dart';
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

Widget _text(BuildContext context, String? value) {
  return Text(
    value == null || value.isEmpty ? '—' : value,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.bodyMedium,
  );
}

final _columns = <CascaTableColumn<StoreListItemModel>>[
  CascaTableColumn(
    id: 'name',
    header: 'Nombre',
    flex: 3,
    sortable: true,
    showOnCompact: true,
    cellBuilder: (context, store) => _text(context, store.name),
  ),
  CascaTableColumn(
    id: 'phone',
    header: 'Teléfono',
    flex: 2,
    cellBuilder: (context, store) => _text(context, store.phone),
  ),
  CascaTableColumn(
    id: 'email',
    header: 'Correo',
    flex: 3,
    cellBuilder: (context, store) => _text(context, store.email),
  ),
  CascaTableColumn(
    id: 'status',
    header: 'Estado',
    flex: 2,
    showOnCompact: true,
    cellBuilder: (context, store) => CascaStatusChip(
      label: store.isActive ? 'Activa' : 'Inactiva',
      tone: store.isActive ? CascaChipTone.success : CascaChipTone.neutral,
    ),
  ),
];

void _openForm(BuildContext context, {String? storeId}) {
  showCascaModal<void>(
    context: context,
    size: CascaModalSize.lg,
    builder: (_) => StoreFormModal(storeId: storeId),
  );
}

class StoreListPage extends ConsumerWidget {
  const StoreListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(storeListQueryProvider);
    final queryController = ref.read(storeListQueryProvider.notifier);
    final stores = ref.watch(storeListProvider);
    final page = stores.value;
    final failed = stores.hasError && page == null;
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    final canCreate = session?.hasPermission('store.create') ?? false;
    final canUpdate = session?.hasPermission('store.update') ?? false;
    final filtered =
        query.search.isNotEmpty || query.status != StoreStatusFilter.all;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CascaPageHeader(
            title: 'Sucursales',
            subtitle: 'Administra las ubicaciones de tu negocio.',
            action: canCreate
                ? CascaButton(
                    label: 'Agregar sucursal',
                    onPressed: () => _openForm(context),
                  )
                : null,
          ),
          const SizedBox(height: CascaSpacing.space5),
          CascaFilterBar(
            searchHint: 'Buscar por nombre...',
            onSearchChanged: queryController.setSearch,
            filter: CascaSelect<StoreStatusFilter>(
              options: [
                for (final filter in StoreStatusFilter.values)
                  CascaSelectOption(value: filter, label: filter.label),
              ],
              value: query.status,
              onChanged: queryController.setStatus,
            ),
          ),
          const SizedBox(height: CascaSpacing.space4),
          CascaTable<StoreListItemModel>(
            columns: _columns,
            rows: page?.items ?? const [],
            rowKey: (store) => store.id,
            loading: stores.isLoading,
            errorMessage: failed
                ? 'No fue posible obtener las sucursales.'
                : null,
            onRetry: () => ref.invalidate(storeListProvider),
            emptyTitle: filtered
                ? 'No se encontraron sucursales.'
                : 'No hay sucursales.',
            rowActions: [
              if (canUpdate)
                CascaTableRowAction(
                  label: 'Editar',
                  icon: CascaIcons.pencilSimple,
                  onSelected: (store) => _openForm(context, storeId: store.id),
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
