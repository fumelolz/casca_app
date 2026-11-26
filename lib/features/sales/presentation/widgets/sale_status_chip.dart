import 'package:casca_app/features/sales/domain/sale_labels.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:material_ui/material_ui.dart';

class SaleStatusChip extends StatelessWidget {
  const SaleStatusChip(this.status, {super.key});

  final int status;

  @override
  Widget build(BuildContext context) {
    return CascaStatusChip(
      label: saleStatusLabel(status),
      tone: switch (status) {
        0 => CascaChipTone.success,
        cancelledSaleStatus => CascaChipTone.danger,
        _ => CascaChipTone.neutral,
      },
    );
  }
}
