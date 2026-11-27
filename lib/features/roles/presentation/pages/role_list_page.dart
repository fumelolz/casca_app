import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/roles/data/models/role_models.dart';
import 'package:casca_app/features/roles/presentation/providers/role_providers.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:casca_app/shared/ui/casca_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

Widget _count(BuildContext context, int value) {
  return Text(
    '$value',
    textAlign: TextAlign.end,
    style: Theme.of(context).textTheme.bodyMedium,
  );
}

final _columns = <CascaTableColumn<RoleListItemModel>>[
  CascaTableColumn(
    id: 'name',
    header: 'Rol',
    flex: 5,
    showOnCompact: true,
    cellBuilder: (context, role) => Row(
      spacing: CascaSpacing.space2,
      children: [
        Expanded(
          child: CascaTableTwoLineCell(
            title: role.name,
            subtitle: role.description ?? '—',
          ),
        ),
        if (role.isSystem)
          const CascaStatusChip(label: 'Sistema', tone: CascaChipTone.info),
      ],
    ),
  ),
  CascaTableColumn(
    id: 'permissions',
    header: 'Permisos',
    flex: 2,
    align: CascaTableAlign.end,
    cellBuilder: (context, role) => _count(context, role.permissionCount),
  ),
  CascaTableColumn(
    id: 'employees',
    header: 'Empleados',
    flex: 2,
    align: CascaTableAlign.end,
    showOnCompact: true,
    cellBuilder: (context, role) => _count(context, role.employeeCount),
  ),
];

class RoleListPage extends ConsumerWidget {
  const RoleListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(roleListProvider);
    final rows = roles.value;
    final error = roles.error;
    final canCreate = ref.watch(
      authControllerProvider.select(
        (s) => s.session?.hasPermission('role.create') ?? false,
      ),
    );

    return SingleChildScrollView(
      padding: pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          CascaPageHeader(
            title: 'Roles',
            subtitle: 'Define qué puede hacer cada empleado.',
            action: canCreate
                ? CascaButton(
                    label: 'Crear rol',
                    onPressed: () => context.go(AppRoutes.roleNew),
                  )
                : null,
          ),
          CascaTable<RoleListItemModel>(
            columns: _columns,
            rows: rows ?? const [],
            rowKey: (role) => role.id,
            loading: roles.isLoading,
            errorMessage: error != null && rows == null
                ? apiErrorMessage(
                    error,
                    'No fue posible obtener los roles.',
                    forbidden: 'No tienes permiso para ver los roles.',
                  )
                : null,
            onRetry: () => ref.invalidate(roleListProvider),
            emptyTitle: 'No hay roles.',
            onRowTap: (role) => context.go(AppRoutes.roleFor(role.id)),
          ),
        ],
      ),
    );
  }
}
