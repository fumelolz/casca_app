import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/customers/customer_avatar.dart';
import 'package:casca_app/core/customers/customer_form_modal.dart';
import 'package:casca_app/core/customers/customer_model.dart';
import 'package:casca_app/core/customers/customer_rules.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/pos/presentation/providers/pos_customer_provider.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class PosCustomerModal extends ConsumerStatefulWidget {
  const PosCustomerModal({super.key});

  @override
  ConsumerState<PosCustomerModal> createState() => _PosCustomerModalState();
}

class _PosCustomerModalState extends ConsumerState<PosCustomerModal> {
  String _term = '';

  Future<void> _register() async {
    final navigator = Navigator.of(context);
    final created = await showCascaModal<CustomerModel>(
      context: context,
      builder: (_) => const CustomerFormModal(),
    );
    if (created != null && mounted) navigator.pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final search = customerSearchProvider(_term);
    final results = ref.watch(search);
    final customers = results.value;
    final canCreate = ref.watch(
      authControllerProvider.select(
        (s) => s.session?.hasPermission('customer.create') ?? false,
      ),
    );

    return CascaModal(
      title: 'Agregar cliente',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (canCreate)
          CascaButton(label: 'Registrar cliente', onPressed: _register),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          CascaInput(
            hintText: 'Buscar por nombre, teléfono o correo...',
            iconStart: CascaIcons.magnifyingGlass,
            clearable: true,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (typed) => setState(() => _term = typed.trim()),
          ),
          if (results.error case final error? when !results.isLoading) ...[
            Text(
              apiErrorMessage(
                error,
                'No fue posible buscar clientes.',
                forbidden: 'No tienes permiso para ver los clientes.',
              ),
              style: textTheme.bodyMedium?.copyWith(color: colors.danger),
            ),
            CascaButton(
              label: 'Reintentar',
              variant: CascaButtonVariant.secondary,
              onPressed: () => ref.invalidate(search),
            ),
          ] else if (customers == null || results.isLoading)
            const CascaSkeleton(height: CascaSpacing.space8)
          else if (customers.isEmpty)
            Text(
              'No se encontraron clientes.',
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            )
          else
            for (final customer in customers)
              Semantics(
                button: true,
                child: InkWell(
                  borderRadius: CascaRadius.md,
                  onTap: () => Navigator.of(context).pop(customer),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: CascaSpacing.space2,
                    ),
                    child: Row(
                      spacing: CascaSpacing.space3,
                      children: [
                        CustomerAvatar(customer: customer),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName(customer),
                                style: textTheme.bodyMedium,
                              ),
                              Text(
                                customerContact(customer),
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (!customer.isConfirmed)
                          const CascaStatusChip(
                            label: 'Pendiente',
                            tone: CascaChipTone.warning,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
