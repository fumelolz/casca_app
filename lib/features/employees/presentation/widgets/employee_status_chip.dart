import 'package:casca_app/features/employees/data/models/employee_models.dart';
import 'package:casca_app/features/employees/domain/employee_rules.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

class EmployeeStatusChip extends StatelessWidget {
  const EmployeeStatusChip({super.key, required this.employee});

  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    final status = employeeStatus(employee);

    return CascaStatusChip(
      label: status.label,
      tone: switch (status) {
        EmployeeStatus.active => CascaChipTone.success,
        EmployeeStatus.inactive => CascaChipTone.neutral,
        EmployeeStatus.invitationPending => CascaChipTone.warning,
        EmployeeStatus.invitationDeclined => CascaChipTone.danger,
      },
    );
  }
}
