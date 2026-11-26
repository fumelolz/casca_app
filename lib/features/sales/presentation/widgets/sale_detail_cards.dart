import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/sales/data/models/sale_history_model.dart';
import 'package:casca_app/features/sales/domain/sale_labels.dart';
import 'package:casca_app/features/sales/presentation/widgets/sale_status_chip.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:material_ui/material_ui.dart';

class SaleHeaderCard extends StatelessWidget {
  const SaleHeaderCard({super.key, required this.sale});

  final SaleDetailModel sale;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final cash = saleCashSummary(sale.payments);
    final modifiedAt = sale.modifiedAt;
    final notes = sale.notes;

    return CascaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: CascaSpacing.space3,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: CascaSpacing.space1,
                  children: [
                    Text(sale.saleNumber, style: textTheme.titleLarge),
                    Text(
                      formatDateTime(sale.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SaleStatusChip(sale.status),
            ],
          ),
          Divider(color: colors.border, height: CascaSpacing.space1),
          Wrap(
            spacing: CascaSpacing.space7,
            runSpacing: CascaSpacing.space3,
            children: [
              _Field('Cliente', sale.customerName ?? 'Venta mostrador'),
              for (final payment in sale.payments)
                _Field(
                  'Pago (${salePaymentMethodLabel(payment.method)})',
                  formatMoney(payment.amount),
                ),
              if (cash != null) ...[
                _Field('Efectivo recibido', formatMoney(cash.received)),
                _Field('Cambio', formatMoney(cash.change)),
              ],
              if (modifiedAt != null)
                _Field('Última actualización', formatDateTime(modifiedAt)),
            ],
          ),
          if (notes != null && notes.isNotEmpty) _Field('Notas', notes),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: context.casca.textSecondary,
          ),
        ),
        Text(value, style: textTheme.bodyMedium),
      ],
    );
  }
}
