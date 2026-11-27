import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/customers/customer_model.dart';
import 'package:casca_app/core/customers/customer_rules.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_customer_provider.dart';
import 'package:casca_app/features/pos/presentation/widgets/pos_customer_modal.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class PosCustomerField extends ConsumerWidget {
  const PosCustomerField({super.key});

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(saleCustomerProvider.notifier);
    final customer = await showCascaModal<CustomerModel>(
      context: context,
      builder: (_) => const PosCustomerModal(),
    );
    if (customer != null) controller.select(customer);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canView = ref.watch(
      authControllerProvider.select(
        (s) => s.session?.hasPermission('customer.view') ?? false,
      ),
    );
    if (!canView) return const SizedBox.shrink();

    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final customer = ref.watch(saleCustomerProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: CascaSpacing.space3),
      padding: const EdgeInsets.symmetric(
        horizontal: CascaSpacing.space3,
        vertical: CascaSpacing.space2,
      ),
      decoration: BoxDecoration(
        borderRadius: CascaRadius.md,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        spacing: CascaSpacing.space3,
        children: [
          CascaIcon(
            CascaIcons.addressBook,
            size: CascaSpacing.space5,
            color: colors.textSecondary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cliente', style: textTheme.bodySmall),
                Text(
                  customer == null ? 'Venta mostrador' : customerName(customer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          CascaButton(
            label: customer == null ? 'Elegir' : 'Cambiar',
            variant: CascaButtonVariant.text,
            size: CascaButtonSize.sm,
            onPressed: () => _choose(context, ref),
          ),
          if (customer != null)
            CascaButton(
              label: 'Quitar',
              variant: CascaButtonVariant.text,
              size: CascaButtonSize.sm,
              onPressed: () =>
                  ref.read(saleCustomerProvider.notifier).select(null),
            ),
        ],
      ),
    );
  }
}
