import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/customers/customer_model.dart';
import 'package:casca_app/core/customers/customer_rules.dart';
import 'package:casca_app/features/customers/presentation/providers/customer_providers.dart';
import 'package:casca_app/core/customers/customer_avatar.dart';
import 'package:casca_app/shared/formatters/date_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class CustomerDetailModal extends ConsumerStatefulWidget {
  const CustomerDetailModal({
    super.key,
    required this.customer,
    required this.canManage,
  });

  final CustomerModel customer;
  final bool canManage;

  @override
  ConsumerState<CustomerDetailModal> createState() =>
      _CustomerDetailModalState();
}

class _CustomerDetailModalState extends ConsumerState<CustomerDetailModal> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _editingEmail = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _saveEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final saved = await ref
        .read(customerConfirmationProvider(widget.customer.id).notifier)
        .correctEmail(normalizeEmail(_email.text));
    if (saved && mounted) setState(() => _editingEmail = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final customer = widget.customer;
    final provider = customerConfirmationProvider(customer.id);
    final confirmation = ref.watch(provider);
    final sending = confirmation.isLoading;
    final result = confirmation.value;
    final email = result?.correctedEmail ?? customer.email;
    final pending = !customer.isConfirmed;
    final createdAt = customer.createdAt;
    Text message(String text, Color color) =>
        Text(text, style: textTheme.bodySmall?.copyWith(color: color));
    Widget detail(String label, String? value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          Text(
            value == null || value.isEmpty ? '—' : value,
            style: textTheme.bodyMedium,
          ),
        ],
      );
    }

    return CascaModal(
      title: 'Cliente',
      actions: [
        CascaButton(
          label: 'Cerrar',
          variant: CascaButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space3,
        children: [
          Row(
            spacing: CascaSpacing.space3,
            children: [
              CustomerAvatar(customer: customer),
              Expanded(
                child: Text(
                  customerName(customer),
                  style: textTheme.titleMedium,
                ),
              ),
              CascaStatusChip(
                label: pending ? 'Pendiente' : 'Confirmado',
                tone: pending ? CascaChipTone.warning : CascaChipTone.success,
              ),
            ],
          ),
          detail('Teléfono', customer.phone),
          detail('Correo', email),
          detail('Notas', customer.notes),
          if (createdAt != null)
            detail('Registrado', formatDateTime(createdAt)),
          if (widget.canManage && pending) ...[
            if (_editingEmail)
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: CascaSpacing.space2,
                  children: [
                    CascaInput(
                      controller: _email,
                      hintText: 'Nuevo correo',
                      maxLength: maxEmailLength,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      validator: validateRequiredEmail,
                    ),
                    CascaButton(
                      label: 'Guardar correo',
                      loading: sending,
                      onPressed: _saveEmail,
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: CascaSpacing.space3,
                runSpacing: CascaSpacing.space2,
                children: [
                  if (email != null)
                    CascaButton(
                      label: 'Reenviar confirmación',
                      loading: sending,
                      onPressed: ref.read(provider.notifier).resend,
                    ),
                  CascaButton(
                    label: 'Corregir correo',
                    variant: CascaButtonVariant.secondary,
                    onPressed: sending
                        ? null
                        : () => setState(() => _editingEmail = true),
                  ),
                ],
              ),
            if (confirmation.error case final error?)
              message(
                apiErrorMessage(
                  error,
                  'No fue posible enviar la confirmación.',
                  forbidden: 'No tienes permiso para esta acción.',
                ),
                colors.danger,
              ),
            if (!sending && result != null)
              result.emailSent
                  ? message('Se envió la confirmación.', colors.success)
                  : message(
                      'No se pudo enviar el correo. Inténtalo más tarde.',
                      colors.warning,
                    ),
          ],
        ],
      ),
    );
  }
}
