import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/employees/data/models/employee_models.dart';
import 'package:casca_app/features/employees/domain/employee_rules.dart';
import 'package:casca_app/features/employees/presentation/providers/employee_providers.dart';
import 'package:casca_app/features/employees/presentation/widgets/employee_modals.dart';
import 'package:casca_app/features/employees/presentation/widgets/employee_status_chip.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_filter_bar.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final _columns = <CascaTableColumn<EmployeeModel>>[
  CascaTableColumn(
    id: 'name',
    header: 'Empleado',
    flex: 4,
    showOnCompact: true,
    cellBuilder: (context, employee) =>
        CascaTableTwoLineCell(title: employee.name, subtitle: employee.email),
  ),
  CascaTableColumn(
    id: 'role',
    header: 'Rol',
    flex: 2,
    cellBuilder: (context, employee) => Text(
      employee.roleName,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  ),
  CascaTableColumn(
    id: 'status',
    header: 'Estado',
    flex: 3,
    showOnCompact: true,
    cellBuilder: (context, employee) => EmployeeStatusChip(employee: employee),
  ),
];

class EmployeeListPage extends ConsumerWidget {
  const EmployeeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(employeeQueryProvider);
    final queryController = ref.read(employeeQueryProvider.notifier);
    final employees = ref.watch(employeeListProvider);
    final page = employees.value;
    final error = employees.error;
    final canCreate = ref.watch(
      authControllerProvider.select(
        (s) => s.session?.hasPermission('storeuser.create') ?? false,
      ),
    );
    final filtered =
        query.search.isNotEmpty || query.status != EmployeeStatusFilter.all;

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          CascaPageHeader(
            title: 'Empleados',
            subtitle: 'Quién trabaja en esta sucursal y qué puede hacer.',
            action: canCreate
                ? CascaButton(
                    label: 'Agregar empleado',
                    onPressed: () => showCascaModal<void>(
                      context: context,
                      builder: (_) => const EmployeeFormModal(),
                    ),
                  )
                : null,
          ),
          CascaFilterBar(
            searchHint: 'Buscar por nombre o correo...',
            onSearchChanged: queryController.setSearch,
            filter: CascaSelect<EmployeeStatusFilter>(
              options: [
                for (final status in EmployeeStatusFilter.values)
                  CascaSelectOption(value: status, label: status.label),
              ],
              value: query.status,
              onChanged: queryController.setStatus,
            ),
          ),
          CascaTable<EmployeeModel>(
            columns: _columns,
            rows: page?.items ?? const [],
            rowKey: (employee) => employee.id,
            loading: employees.isLoading,
            errorMessage: error != null && page == null
                ? apiErrorMessage(
                    error,
                    'No fue posible obtener los empleados.',
                    forbidden: 'No tienes permiso para ver los empleados.',
                  )
                : null,
            onRetry: () => ref.invalidate(employeeListProvider),
            emptyTitle: filtered
                ? 'No se encontraron empleados.'
                : 'No hay empleados.',
            onRowTap: (employee) =>
                context.go(AppRoutes.employeeFor(employee.id)),
            page: query.page,
            pageSize: employeesPageSize,
            totalItems: page?.totalCount,
            onPageChanged: queryController.setPage,
          ),
        ],
      ),
    );
  }
}
