import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/cash_registers/data/models/cash_register_model.dart';
import 'package:casca_app/features/cash_registers/presentation/providers/cash_register_actions_provider.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const int _maxNameLength = 100;
const int _maxDescriptionLength = 500;

class CashRegisterFormModal extends ConsumerStatefulWidget {
  const CashRegisterFormModal({super.key, this.cashRegister});

  final CashRegisterModel? cashRegister;

  @override
  ConsumerState<CashRegisterFormModal> createState() =>
      _CashRegisterFormModalState();
}

class _CashRegisterFormModalState extends ConsumerState<CashRegisterFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.cashRegister?.name,
  );
  late final _descriptionController = TextEditingController(
    text: widget.cashRegister?.description,
  );

  bool get _isEdit => widget.cashRegister != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    return (value?.trim() ?? '').isEmpty ? 'Ingresa el nombre' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final saved = await ref
        .read(cashRegisterFormControllerProvider.notifier)
        .save(
          CashRegisterRequest(
            name: _nameController.text.trim(),
            description: description.isEmpty ? null : description,
          ),
          cashRegisterId: widget.cashRegister?.id,
        );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final saveState = ref.watch(cashRegisterFormControllerProvider);
    final saving = saveState.isLoading;
    final error = saveState.error;
    final labelStyle = textTheme.labelLarge?.copyWith(
      fontWeight: CascaFontWeight.semibold,
    );

    return CascaModal(
      title: _isEdit ? 'Editar caja registradora' : 'Agregar caja registradora',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: saving ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(label: 'Guardar', loading: saving, onPressed: _save),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nombre', style: labelStyle),
            const SizedBox(height: CascaSpacing.space2),
            CascaInput(
              controller: _nameController,
              hintText: 'Nombre de la caja',
              maxLength: _maxNameLength,
              textInputAction: TextInputAction.next,
              validator: _validateName,
            ),
            const SizedBox(height: CascaSpacing.space4),
            Text('Descripción', style: labelStyle),
            const SizedBox(height: CascaSpacing.space2),
            CascaInput(
              controller: _descriptionController,
              hintText: 'Descripción de la caja',
              maxLength: _maxDescriptionLength,
              lines: 3,
            ),
            if (error != null) ...[
              const SizedBox(height: CascaSpacing.space4),
              Text(
                apiErrorMessage(
                  error,
                  _isEdit
                      ? 'No fue posible actualizar la caja registradora.'
                      : 'No fue posible crear la caja registradora.',
                  forbidden: 'No tienes permiso para esta acción.',
                ),
                style: textTheme.bodyMedium?.copyWith(color: colors.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
