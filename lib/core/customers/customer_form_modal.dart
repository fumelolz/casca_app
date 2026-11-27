import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/core/customers/customer_rules.dart';
import 'package:casca_app/core/customers/customer_form_controller.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const int _notesLines = 3;

class CustomerFormModal extends ConsumerStatefulWidget {
  const CustomerFormModal({super.key});

  @override
  ConsumerState<CustomerFormModal> createState() => _CustomerFormModalState();
}

class _CustomerFormModalState extends ConsumerState<CustomerFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  bool _contactMissing = false;

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _phone, _email, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    final missing = !hasContact(_phone.text, _email.text);
    setState(() => _contactMissing = missing);
    if (!valid || missing) return;

    final created = await ref
        .read(customerFormControllerProvider.notifier)
        .create(
          createCustomerRequest(
            firstName: _firstName.text,
            lastName: _lastName.text,
            phone: _phone.text,
            email: _email.text,
            notes: _notes.text,
          ),
        );
    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final saveState = ref.watch(customerFormControllerProvider);
    final saving = saveState.isLoading;
    Widget field(String label, Widget input) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space2,
        children: [
          Text(label, style: textTheme.bodyMedium),
          input,
        ],
      );
    }

    Text error(String message) => Text(
      message,
      style: textTheme.bodyMedium?.copyWith(color: colors.danger),
    );

    return CascaModal(
      title: 'Registrar cliente',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: saving ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(label: 'Registrar', loading: saving, onPressed: _save),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space3,
          children: [
            field(
              'Nombre',
              CascaInput(
                controller: _firstName,
                hintText: 'Nombre',
                maxLength: maxNameLength,
                textInputAction: TextInputAction.next,
                validator: validateFirstName,
              ),
            ),
            field(
              'Apellido',
              CascaInput(
                controller: _lastName,
                hintText: 'Apellido',
                maxLength: maxNameLength,
                textInputAction: TextInputAction.next,
              ),
            ),
            field(
              'Teléfono',
              CascaInput(
                controller: _phone,
                hintText: '10 dígitos',
                maxLength: maxPhoneLength,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: validateCustomerPhone,
              ),
            ),
            field(
              'Correo',
              CascaInput(
                controller: _email,
                hintText: 'correo@ejemplo.com',
                maxLength: maxEmailLength,
                keyboardType: TextInputType.emailAddress,
                validator: validateCustomerEmail,
              ),
            ),
            field(
              'Notas',
              CascaInput(
                controller: _notes,
                hintText: 'Notas del cliente',
                maxLength: maxNotesLength,
                lines: _notesLines,
              ),
            ),
            if (_contactMissing)
              error('Indica al menos un teléfono o un correo.'),
            if (saveState.error case final failure?)
              error(
                apiErrorMessage(
                  failure,
                  'No fue posible registrar al cliente.',
                  forbidden: 'No tienes permiso para registrar clientes.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
