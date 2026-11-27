import 'package:casca_app/features/employees/data/models/employee_models.dart';

const int maxEmployeeName = 120;
const int minEmployeePhone = 10;
const int maxEmployeePhone = 15;
const int maxEmployeeEmail = 150;

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

enum EmployeeStatusFilter {
  all('Todos', null),
  active('Activos', true),
  inactive('Inactivos', false);

  const EmployeeStatusFilter(this.label, this.isActive);

  final String label;
  final bool? isActive;
}

enum EmployeeStatus {
  active('Activo'),
  inactive('Inactivo'),
  invitationPending('Invitación pendiente'),
  invitationDeclined('Invitación rechazada');

  const EmployeeStatus(this.label);

  final String label;
}

EmployeeStatus employeeStatus(EmployeeModel employee) {
  if (employee.acceptancePending) return EmployeeStatus.invitationPending;
  if (employee.acceptanceDeclined) return EmployeeStatus.invitationDeclined;
  if (!employee.isActive) return EmployeeStatus.inactive;
  return employee.invitationPending
      ? EmployeeStatus.invitationPending
      : EmployeeStatus.active;
}

bool canToggleActive(EmployeeModel employee) {
  return !employee.acceptancePending && !employee.acceptanceDeclined;
}

bool canResendInvitation(EmployeeModel employee) {
  return employee.invitationPending ||
      employee.acceptancePending ||
      employee.acceptanceDeclined;
}

String? validateEmployeeName(String? value) {
  return (value ?? '').trim().isEmpty ? 'Escribe el nombre.' : null;
}

String? validateEmployeeEmail(String? value) {
  return _emailPattern.hasMatch((value ?? '').trim())
      ? null
      : 'Escribe un correo válido.';
}

String? validateEmployeePhone(String? value) {
  return (value ?? '').trim().length < minEmployeePhone
      ? 'Escribe al menos $minEmployeePhone dígitos.'
      : null;
}

({String message, bool warning}) createEmployeeNotice(
  CreateEmployeeResult result,
) {
  if (result.pendingAcceptance) {
    return result.invitationSent
        ? (
            message:
                'Invitación enviada. Ya tiene una cuenta en Casca y tendrá '
                'acceso a esta sucursal cuando la acepte en Negocios.',
            warning: false,
          )
        : (
            message:
                'Se creó la invitación, pero no se pudo enviar el correo. '
                'Abre a la persona y reenvíala.',
            warning: true,
          );
  }
  if (result.addedToExistingUser) {
    return (
      message: result.invitationSent
          ? 'Ya tenía una cuenta; se agregó a esta sucursal y se le reenvió '
                'su invitación para crear la contraseña.'
          : 'Ya tenía una cuenta; ahora también tiene acceso a esta sucursal.',
      warning: false,
    );
  }
  return result.invitationSent
      ? (message: 'Se envió la invitación a su correo.', warning: false)
      : (
          message:
              'Se agregó al empleado, pero no se pudo enviar el correo. '
              'Ábrelo y reenvía la invitación.',
          warning: true,
        );
}
