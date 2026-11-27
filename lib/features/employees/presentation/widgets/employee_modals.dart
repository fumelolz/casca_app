import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/employees/data/models/employee_models.dart';
import 'package:casca_app/features/employees/domain/employee_rules.dart';
import 'package:casca_app/features/employees/presentation/providers/employee_providers.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const String _newScope = 'nuevo';

Widget _labeled(BuildContext context, String label, Widget input) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CascaSpacing.space2,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      input,
    ],
  );
}

Widget _error(BuildContext context, Object error, String fallback) {
  return Text(
    apiErrorMessage(
      error,
      fallback,
      forbidden: 'No tienes permiso para esta acción.',
    ),
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.casca.danger),
  );
}

class _RoleField extends ConsumerWidget {
  const _RoleField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(employeeRolesProvider);
    final options = roles.value;

    if (roles.error case final error? when options == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space2,
        children: [
          _error(context, error, 'No fue posible obtener los roles.'),
          CascaButton(
            label: 'Reintentar',
            variant: CascaButtonVariant.secondary,
            onPressed: () => ref.invalidate(employeeRolesProvider),
          ),
        ],
      );
    }
    if (options == null) {
      return const CascaSkeleton(height: CascaSpacing.space8);
    }

    return _labeled(
      context,
      'Rol',
      CascaSelect<String>(
        options: [
          for (final role in options)
            CascaSelectOption(value: role.id, label: role.name),
        ],
        value: value,
        hintText: 'Selecciona un rol',
        onChanged: onChanged,
      ),
    );
  }
}

class EmployeeFormModal extends ConsumerStatefulWidget {
  const EmployeeFormModal({super.key, this.employee});

  final EmployeeModel? employee;

  @override
  ConsumerState<EmployeeFormModal> createState() => _EmployeeFormModalState();
}

class _EmployeeFormModalState extends ConsumerState<EmployeeFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.employee?.name);
  late final _email = TextEditingController(text: widget.employee?.email);
  late final _phone = TextEditingController(text: widget.employee?.phone);
  String? _roleId;
  bool _roleMissing = false;
  String? _notice;
  bool _warning = false;

  bool get _editing => widget.employee != null;
  String get _scope => widget.employee?.id ?? _newScope;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    final missing = !_editing && _roleId == null;
    setState(() => _roleMissing = missing);
    if (!valid || missing) return;

    final id = widget.employee?.id;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final roleId = _roleId;
    CreateEmployeeResult? created;

    final saved = await ref.read(employeeActionProvider(_scope).notifier).run((
      repository,
    ) async {
      if (id != null) {
        await repository.updateEmployee(id, {'name': name, 'phone': phone});
      } else {
        created = await repository.createEmployee({
          'name': name,
          'email': email,
          'phone': phone,
          'roleId': roleId,
        });
      }
      return null;
    }, employeeId: id);
    if (!saved || !mounted) return;

    if (created case final result?) {
      final notice = createEmployeeNotice(result);
      setState(() {
        _notice = notice.message;
        _warning = notice.warning;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final action = ref.watch(employeeActionProvider(_scope));
    final saving = action.isLoading;
    final notice = _notice;

    if (notice != null) {
      return CascaModal(
        title: 'Empleado agregado',
        actions: [
          CascaButton(
            label: 'Listo',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        child: Text(
          notice,
          style: textTheme.bodyMedium?.copyWith(
            color: _warning ? colors.warning : null,
          ),
        ),
      );
    }

    return CascaModal(
      title: _editing ? 'Editar empleado' : 'Agregar empleado',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: saving ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(
          label: _editing ? 'Guardar' : 'Agregar',
          loading: saving,
          onPressed: _save,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space3,
          children: [
            _labeled(
              context,
              'Nombre',
              CascaInput(
                controller: _name,
                hintText: 'Nombre completo',
                maxLength: maxEmployeeName,
                validator: validateEmployeeName,
              ),
            ),
            _labeled(
              context,
              'Correo',
              CascaInput(
                controller: _email,
                enabled: !_editing,
                hintText: 'correo@ejemplo.com',
                maxLength: maxEmployeeEmail,
                keyboardType: TextInputType.emailAddress,
                validator: _editing ? null : validateEmployeeEmail,
              ),
            ),
            _labeled(
              context,
              'Teléfono',
              CascaInput(
                controller: _phone,
                hintText: '10 dígitos',
                maxLength: maxEmployeePhone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: validateEmployeePhone,
              ),
            ),
            if (!_editing) ...[
              _RoleField(
                value: _roleId,
                onChanged: (id) => setState(() {
                  _roleId = id;
                  _roleMissing = false;
                }),
              ),
              if (_roleMissing)
                Text(
                  'Selecciona un rol.',
                  style: textTheme.bodySmall?.copyWith(color: colors.danger),
                ),
              Text(
                'Si es nuevo, recibirá un correo para crear su contraseña. Si '
                'ya tiene cuenta en otro negocio, tendrá acceso cuando acepte '
                'la invitación.',
                style: textTheme.bodySmall,
              ),
            ],
            if (action.error case final error?)
              _error(
                context,
                error,
                _editing
                    ? 'No fue posible actualizar al empleado.'
                    : 'No fue posible agregar al empleado.',
              ),
          ],
        ),
      ),
    );
  }
}

class EmployeeRoleModal extends ConsumerStatefulWidget {
  const EmployeeRoleModal({super.key, required this.employee});

  final EmployeeModel employee;

  @override
  ConsumerState<EmployeeRoleModal> createState() => _EmployeeRoleModalState();
}

class _EmployeeRoleModalState extends ConsumerState<EmployeeRoleModal> {
  late String _roleId = widget.employee.roleId;

  Future<void> _save() async {
    final id = widget.employee.id;
    final roleId = _roleId;
    final saved = await ref.read(employeeActionProvider(id).notifier).run((
      repository,
    ) async {
      await repository.changeRole(id, roleId);
      return null;
    }, employeeId: id);
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(employeeActionProvider(widget.employee.id));

    return CascaModal(
      title: 'Cambiar rol',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: action.isLoading
              ? null
              : () => Navigator.of(context).pop(),
        ),
        CascaButton(
          label: 'Guardar',
          loading: action.isLoading,
          onPressed: _roleId == widget.employee.roleId ? null : _save,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          Text('Rol actual: ${widget.employee.roleName}'),
          _RoleField(
            value: _roleId,
            onChanged: (id) => setState(() => _roleId = id),
          ),
          if (action.error case final error?)
            _error(context, error, 'No fue posible cambiar el rol.'),
        ],
      ),
    );
  }
}
