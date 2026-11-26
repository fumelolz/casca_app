import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/auth/business_type_options.dart';
import 'package:casca_app/core/auth/register_request.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/businesses/presentation/providers/business_providers.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const int _maxNameLength = 100;

class BusinessFormModal extends ConsumerStatefulWidget {
  const BusinessFormModal({super.key});

  @override
  ConsumerState<BusinessFormModal> createState() => _BusinessFormModalState();
}

class _BusinessFormModalState extends ConsumerState<BusinessFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  BusinessType? _businessType;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    final created = await ref
        .read(createBusinessProvider.notifier)
        .create(name: _name.text.trim(), businessType: _businessType!);
    if (created && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(createBusinessProvider);
    final saving = state.isLoading;
    final error = state.error;
    final labelStyle = textTheme.labelLarge?.copyWith(
      fontWeight: CascaFontWeight.semibold,
    );

    return CascaModal(
      title: 'Agregar negocio',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: saving ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(
          label: 'Crear negocio',
          loading: saving,
          onPressed: _create,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space2,
          children: [
            Text('Nombre del negocio', style: labelStyle),
            CascaInput(
              controller: _name,
              hintText: 'Ej. Plásticos Lupita',
              maxLength: _maxNameLength,
              validator: (text) =>
                  (text ?? '').trim().isEmpty ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: CascaSpacing.space1),
            Text('Giro', style: labelStyle),
            CascaSelect<BusinessType>(
              options: businessTypeOptions,
              value: _businessType,
              hintText: 'Selecciona un giro',
              enabled: !saving,
              validator: (value) => value == null ? 'Selecciona un giro' : null,
              onChanged: (value) => setState(() => _businessType = value),
            ),
            const SizedBox(height: CascaSpacing.space1),
            Text(
              'Se crea con su propia sucursal principal y su propio catálogo. '
              'Al terminar cambiarás a este negocio.',
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            if (error != null)
              Text(
                apiErrorMessage(
                  error,
                  'No fue posible crear el negocio.',
                  forbidden: 'Solo un administrador puede agregar negocios.',
                ),
                style: textTheme.bodyMedium?.copyWith(color: colors.danger),
              ),
          ],
        ),
      ),
    );
  }
}
