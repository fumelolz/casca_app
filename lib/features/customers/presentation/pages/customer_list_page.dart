import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/customers/customer_model.dart';
import 'package:casca_app/core/customers/customer_rules.dart';
import 'package:casca_app/features/customers/presentation/providers/customer_providers.dart';
import 'package:casca_app/core/customers/customer_avatar.dart';
import 'package:casca_app/features/customers/presentation/widgets/customer_detail_modal.dart';
import 'package:casca_app/core/customers/customer_form_modal.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_filter_bar.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

final _columns = <CascaTableColumn<CustomerModel>>[
  CascaTableColumn(
    id: 'name',
    header: 'Cliente',
    flex: 4,
    showOnCompact: true,
    cellBuilder: (context, customer) => Row(
      spacing: CascaSpacing.space3,
      children: [
        CustomerAvatar(customer: customer),
        Expanded(
          child: CascaTableTwoLineCell(
            title: customerName(customer),
            subtitle: customerContact(customer),
          ),
        ),
      ],
    ),
  ),
  CascaTableColumn(
    id: 'email',
    header: 'Correo',
    flex: 3,
    cellBuilder: (context, customer) => Text(
      customer.email ?? '—',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ),
  CascaTableColumn(
    id: 'status',
    header: 'Estado',
    flex: 2,
    showOnCompact: true,
    cellBuilder: (context, customer) => CascaStatusChip(
      label: customer.isConfirmed ? 'Confirmado' : 'Pendiente',
      tone: customer.isConfirmed
          ? CascaChipTone.success
          : CascaChipTone.warning,
    ),
  ),
];

class CustomerListPage extends ConsumerWidget {
  const CustomerListPage({super.key});

  Future<void> _register(BuildContext context, WidgetRef ref) async {
    final created = await showCascaModal<CustomerModel>(
      context: context,
      builder: (_) => const CustomerFormModal(),
    );
    if (created != null && context.mounted) {
      ref.invalidate(customerListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(customerQueryProvider);
    final queryController = ref.read(customerQueryProvider.notifier);
    final customers = ref.watch(customerListProvider);
    final page = customers.value;
    final error = customers.error;
    final canCreate = ref.watch(
      authControllerProvider.select(
        (s) => s.session?.hasPermission('customer.create') ?? false,
      ),
    );
    final filtered =
        query.search.isNotEmpty || query.status != CustomerStatusFilter.all;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CascaPageHeader(
            title: 'Clientes',
            subtitle: 'Consulta y registra a tus clientes.',
            action: canCreate
                ? CascaButton(
                    label: 'Registrar cliente',
                    onPressed: () => _register(context, ref),
                  )
                : null,
          ),
          const SizedBox(height: CascaSpacing.space5),
          CascaFilterBar(
            searchHint: 'Buscar por nombre, teléfono o correo...',
            onSearchChanged: queryController.setSearch,
            filter: CascaSelect<CustomerStatusFilter>(
              options: [
                for (final status in CustomerStatusFilter.values)
                  CascaSelectOption(value: status, label: status.label),
              ],
              value: query.status,
              onChanged: queryController.setStatus,
            ),
          ),
          const SizedBox(height: CascaSpacing.space4),
          CascaTable<CustomerModel>(
            columns: _columns,
            rows: page?.items ?? const [],
            rowKey: (customer) => customer.id,
            loading: customers.isLoading,
            errorMessage: error != null && page == null
                ? apiErrorMessage(
                    error,
                    'No fue posible obtener los clientes.',
                    forbidden: 'No tienes permiso para ver los clientes.',
                  )
                : null,
            onRetry: () => ref.invalidate(customerListProvider),
            emptyTitle: filtered
                ? 'No se encontraron clientes.'
                : 'No hay clientes.',
            emptyMessage: filtered
                ? 'Prueba con otra búsqueda.'
                : 'Registra un cliente para empezar.',
            onRowTap: (customer) => showCascaModal<void>(
              context: context,
              builder: (_) =>
                  CustomerDetailModal(customer: customer, canManage: canCreate),
            ),
            page: query.page,
            pageSize: customersPageSize,
            totalItems: page?.totalCount,
            onPageChanged: queryController.setPage,
          ),
        ],
      ),
    );
  }
}
