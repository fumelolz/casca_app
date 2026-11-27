import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/employees/data/models/employee_models.dart';
import 'package:casca_app/features/employees/presentation/providers/employee_providers.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class CashRegisterAccessCard extends ConsumerStatefulWidget {
  const CashRegisterAccessCard({
    super.key,
    required this.employee,
    required this.canManage,
  });

  final EmployeeModel employee;
  final bool canManage;

  @override
  ConsumerState<CashRegisterAccessCard> createState() =>
      _CashRegisterAccessCardState();
}

class _CashRegisterAccessCardState
    extends ConsumerState<CashRegisterAccessCard> {
  Set<String>? _draft;

  String get _scope => 'cajas-${widget.employee.id}';

  Future<void> _save(Set<String> selected) async {
    final id = widget.employee.id;
    final saved = await ref.read(employeeActionProvider(_scope).notifier).run((
      repository,
    ) async {
      await repository.updateCashRegisterAccess(id, selected);
      return 'Accesos actualizados.';
    });
    if (!saved || !mounted) return;
    ref.invalidate(cashRegisterAccessProvider(id));
    ref.invalidate(employeeDetailProvider(id));
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    final editable =
        widget.canManage &&
        employee.isActive &&
        !employee.hasFullCashRegisterAccess;

    return CascaCard(
      title: 'Acceso a cajas',
      child: editable
          ? _editor(context)
          : Text(
              employee.hasFullCashRegisterAccess
                  ? 'Acceso total: puede operar todas las cajas por su rol.'
                  : employee.cashRegisterNames.isEmpty
                  ? 'No tiene cajas asignadas.'
                  : employee.cashRegisterNames.join(', '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
    );
  }

  Widget _editor(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final provider = cashRegisterAccessProvider(widget.employee.id);
    final access = ref.watch(provider);
    final action = ref.watch(employeeActionProvider(_scope));
    final registers = access.value;

    if (registers == null) {
      final error = access.error;
      if (error == null) {
        return const CascaSkeleton(height: CascaSpacing.space8);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space2,
        children: [
          Text(
            apiErrorMessage(
              error,
              'No fue posible obtener las cajas del empleado.',
              forbidden: 'No tienes permiso para administrar el acceso.',
            ),
          ),
          CascaButton(
            label: 'Reintentar',
            variant: CascaButtonVariant.secondary,
            onPressed: () => ref.invalidate(provider),
          ),
        ],
      );
    }
    if (registers.isEmpty) {
      return const Text('No hay cajas registradoras en la tienda.');
    }

    final saved = {
      for (final register in registers)
        if (register.hasAccess) register.id,
    };
    final selected = _draft ?? saved;
    final dirty =
        selected.length != saved.length || !selected.containsAll(saved);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space2,
      children: [
        Text(
          'Cajas que puede abrir y operar. Quitar una no cierra un turno '
          'abierto.',
          style: textTheme.bodySmall,
        ),
        for (final register in registers)
          Row(
            children: [
              CascaCheckbox(
                value: selected.contains(register.id),
                semanticLabel: 'Acceso a ${register.name}',
                onChanged: (checked) => setState(
                  () => _draft = checked
                      ? {...selected, register.id}
                      : selected.difference({register.id}),
                ),
              ),
              Expanded(child: Text(register.name, style: textTheme.bodyMedium)),
            ],
          ),
        CascaButton(
          label: 'Guardar accesos',
          loading: action.isLoading,
          onPressed: dirty ? () => _save(selected) : null,
        ),
        if (action.error case final error?)
          Text(
            apiErrorMessage(error, 'No fue posible guardar los accesos.'),
            style: textTheme.bodySmall?.copyWith(color: colors.danger),
          ),
        if (!dirty && action.value != null)
          Text(
            action.value!,
            style: textTheme.bodySmall?.copyWith(color: colors.success),
          ),
      ],
    );
  }
}
