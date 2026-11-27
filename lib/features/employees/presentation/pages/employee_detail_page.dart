import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/layout/page_padding.dart';
import 'package:casca_app/core/routing/app_routes.dart';
import 'package:casca_app/features/employees/data/models/employee_models.dart';
import 'package:casca_app/features/employees/domain/employee_rules.dart';
import 'package:casca_app/features/employees/presentation/providers/employee_providers.dart';
import 'package:casca_app/features/employees/presentation/widgets/cash_register_access_card.dart';
import 'package:casca_app/features/employees/presentation/widgets/employee_modals.dart';
import 'package:casca_app/features/employees/presentation/widgets/employee_status_chip.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_page_header.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const double _skeletonHeight = 140;

class EmployeeDetailPage extends ConsumerWidget {
  const EmployeeDetailPage({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void back() => context.go(AppRoutes.employees);
    final detail = ref.watch(employeeDetailProvider(employeeId));
    final employee = detail.value;
    final error = detail.error;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: SingleChildScrollView(
        padding: pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space4,
          children: [
            CascaPageHeader(
              title: 'Empleado',
              subtitle: 'Datos, rol y acceso a cajas.',
              action: CascaButton(
                label: 'Volver a empleados',
                variant: CascaButtonVariant.secondary,
                onPressed: back,
              ),
            ),
            if (employee != null)
              ..._content(context, ref, employee)
            else if (error == null)
              const CascaSkeleton(height: _skeletonHeight)
            else ...[
              Text(
                apiErrorMessage(
                  error,
                  'No fue posible obtener el empleado.',
                  forbidden: 'No tienes permiso para ver a este empleado.',
                ),
                textAlign: TextAlign.center,
              ),
              CascaButton(
                label: 'Reintentar',
                variant: CascaButtonVariant.secondary,
                onPressed: () =>
                    ref.invalidate(employeeDetailProvider(employeeId)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    EmployeeModel employee,
  ) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(authControllerProvider.select((s) => s.session));
    bool can(String permission) => session?.hasPermission(permission) ?? false;
    final scope = 'estado-${employee.id}';
    final action = ref.watch(employeeActionProvider(scope));
    final createdAt = employee.createdAt;
    final lastLogin = employee.lastLogin;
    final declined = employee.acceptanceDeclined;
    Widget row(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        Text(value, style: textTheme.bodyMedium),
      ],
    );

    void toggle() => ref.read(employeeActionProvider(scope).notifier).run((
      repository,
    ) async {
      await repository.setActive(employee.id, active: !employee.isActive);
      return employee.isActive ? 'Empleado desactivado.' : 'Empleado activado.';
    }, employeeId: employee.id);
    void resend() => ref.read(employeeActionProvider(scope).notifier).run((
      repository,
    ) async {
      final sent = await repository.resendInvitation(employee.id);
      return sent
          ? 'Se envió la invitación a su correo.'
          : 'No se pudo enviar el correo. Inténtalo más tarde.';
    }, employeeId: employee.id);

    return [
      CascaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space3,
          children: [
            Row(
              spacing: CascaSpacing.space3,
              children: [
                Expanded(
                  child: Text(employee.name, style: textTheme.titleLarge),
                ),
                EmployeeStatusChip(employee: employee),
              ],
            ),
            row('Correo', employee.email),
            if (employee.phone.isNotEmpty) row('Teléfono', employee.phone),
            row('Rol', employee.roleName),
            row(
              'Última sesión',
              lastLogin == null ? 'Nunca' : formatDateTime(lastLogin),
            ),
            if (createdAt != null) row('Alta', formatDateTime(createdAt)),
            Wrap(
              spacing: CascaSpacing.space3,
              runSpacing: CascaSpacing.space2,
              children: [
                if (can('storeuser.update')) ...[
                  CascaButton(
                    label: 'Editar',
                    onPressed: () => showCascaModal<void>(
                      context: context,
                      builder: (_) => EmployeeFormModal(employee: employee),
                    ),
                  ),
                  CascaButton(
                    label: 'Cambiar rol',
                    variant: CascaButtonVariant.secondary,
                    onPressed: () => showCascaModal<void>(
                      context: context,
                      size: CascaModalSize.sm,
                      builder: (_) => EmployeeRoleModal(employee: employee),
                    ),
                  ),
                  if (canToggleActive(employee))
                    CascaButton(
                      label: employee.isActive ? 'Desactivar' : 'Activar',
                      variant: employee.isActive
                          ? CascaButtonVariant.danger
                          : CascaButtonVariant.secondary,
                      loading: action.isLoading,
                      onPressed: toggle,
                    ),
                ],
                if (can('storeuser.create') && canResendInvitation(employee))
                  CascaButton(
                    label: declined
                        ? 'Volver a invitar'
                        : 'Reenviar invitación',
                    variant: CascaButtonVariant.secondary,
                    loading: action.isLoading,
                    onPressed: resend,
                  ),
              ],
            ),
            if (action.error case final error?)
              Text(
                apiErrorMessage(
                  error,
                  'No fue posible completar la acción.',
                  forbidden: 'No tienes permiso para esta acción.',
                ),
                style: textTheme.bodySmall?.copyWith(color: colors.danger),
              ),
            if (action.value case final message?)
              Text(message, style: textTheme.bodySmall),
          ],
        ),
      ),
      CashRegisterAccessCard(
        key: ValueKey(employee.id),
        employee: employee,
        canManage: can('cashregister.access.manage'),
      ),
    ];
  }
}
