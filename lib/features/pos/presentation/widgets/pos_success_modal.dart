import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_sale_provider.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:material_ui/material_ui.dart';

class PosSuccessModal extends StatelessWidget {
  const PosSuccessModal({super.key, required this.completed});

  final CompletedSale completed;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final sale = completed.sale;
    final received = completed.payment.receivedCents;
    final change = completed.payment.changeCents;
    final customer = sale.customerName;

    Widget row(String label, int cents, {bool strong = false}) {
      final style = strong ? textTheme.titleLarge : textTheme.bodyMedium;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(formatMoney(cents / 100), style: style),
        ],
      );
    }

    return CascaModal(
      title: 'Venta registrada',
      actions: [
        CascaButton(
          label: 'Nueva venta',
          size: CascaButtonSize.lg,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          Center(
            child: CascaIcon(
              CascaIcons.circleCheck,
              size: CascaSpacing.space8,
              color: colors.success,
            ),
          ),
          Text(
            '¡Venta registrada!',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          Text(
            'Ticket ${sale.saleNumber}',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          if (customer != null) Text(customer, textAlign: TextAlign.center),
          Text(
            formatMoney(sale.totalAmount),
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontSize: CascaFontSize.xxl,
              fontWeight: CascaFontWeight.semibold,
            ),
          ),
          if (received != null && change != null) ...[
            Divider(color: colors.border),
            row('Efectivo recibido', received),
            row('Cambio a entregar', change, strong: true),
          ],
        ],
      ),
    );
  }
}
