import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/stores/domain/store_form_rules.dart';
import 'package:casca_app/features/stores/presentation/providers/store_form_provider.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const double _twoColumnsMinWidth = 440;

class StoreFormModal extends ConsumerWidget {
  const StoreFormModal({super.key, this.storeId});

  final String? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = storeId;
    if (id == null) return const _StoreForm();

    final detail = ref.watch(storeDetailProvider(id));
    final data = detail.value;
    if (data != null) return _StoreForm(storeId: id, current: data);

    final error = detail.error;
    return CascaModal(
      title: 'Editar sucursal',
      actions: [
        if (error != null)
          CascaButton(
            label: 'Reintentar',
            variant: CascaButtonVariant.secondary,
            onPressed: () => ref.invalidate(storeDetailProvider(id)),
          ),
      ],
      child: Center(
        child: error == null
            ? const _StoreFormSkeleton()
            : Text(
                apiErrorMessage(
                  error,
                  'No fue posible obtener la sucursal.',
                  forbidden: 'No tienes permiso para ver esta sucursal.',
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}

class _StoreFormSkeleton extends StatelessWidget {
  const _StoreFormSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando sucursal',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 5; i++) ...const [
            CascaSkeleton(width: 96),
            SizedBox(height: CascaSpacing.space2),
            CascaSkeleton(width: double.infinity, height: CascaSpacing.space8),
            SizedBox(height: CascaSpacing.space4),
          ],
        ],
      ),
    );
  }
}

class _StoreForm extends ConsumerStatefulWidget {
  const _StoreForm({this.storeId, this.current});

  final String? storeId;
  final Map<String, dynamic>? current;

  @override
  ConsumerState<_StoreForm> createState() => _StoreFormState();
}

class _StoreFormState extends ConsumerState<_StoreForm> {
  final _formKey = GlobalKey<FormState>();
  late final StoreFormValues _initial = widget.current == null
      ? const StoreFormValues()
      : StoreFormValues.fromDetail(widget.current!);
  late final _name = TextEditingController(text: _initial.name);
  late final _phone = TextEditingController(text: _initial.phone);
  late final _email = TextEditingController(text: _initial.email);
  late final _street = TextEditingController(text: _initial.street);
  late final _exterior = TextEditingController(text: _initial.exteriorNumber);
  late final _interior = TextEditingController(text: _initial.interiorNumber);
  late final _municipality = TextEditingController(text: _initial.municipality);
  late final _city = TextEditingController(text: _initial.city);
  late final _state = TextEditingController(text: _initial.state);
  late final _postalCode = TextEditingController(text: _initial.postalCode);
  late final _country = TextEditingController(text: _initial.country);

  bool get _isEdit => widget.storeId != null;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _email,
      _street,
      _exterior,
      _interior,
      _municipality,
      _city,
      _state,
      _postalCode,
      _country,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final values = StoreFormValues(
      name: _name.text,
      phone: _phone.text,
      email: _email.text,
      street: _street.text,
      exteriorNumber: _exterior.text,
      interiorNumber: _interior.text,
      municipality: _municipality.text,
      city: _city.text,
      state: _state.text,
      postalCode: _postalCode.text,
      country: _country.text,
    );
    final current = widget.current;
    final tenantId =
        ref.read(authControllerProvider).session?.activeStore.tenantId ?? '';

    final saved = await ref
        .read(storeFormControllerProvider.notifier)
        .save(
          current == null
              ? toCreateStoreRequest(values, tenantId)
              : toUpdateStoreRequest(values, current),
          storeId: widget.storeId,
        );
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final saveState = ref.watch(storeFormControllerProvider);
    final saving = saveState.isLoading;
    final error = saveState.error;

    return CascaModal(
      title: _isEdit ? 'Editar sucursal' : 'Agregar sucursal',
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
            _Field(
              label: 'Nombre',
              controller: _name,
              hint: 'Ej. Sucursal Centro',
              maxLength: 50,
              validator: validateStoreName,
            ),
            _Pair(
              _Field(
                label: 'Teléfono',
                controller: _phone,
                hint: '10 dígitos',
                maxLength: 20,
                keyboardType: TextInputType.phone,
                validator: validatePhone,
              ),
              _Field(
                label: 'Correo',
                controller: _email,
                hint: 'correo@ejemplo.com',
                maxLength: 255,
                keyboardType: TextInputType.emailAddress,
                validator: validateOptionalEmail,
              ),
            ),
            _Field(
              label: 'Calle',
              controller: _street,
              hint: 'Ej. Av. Juárez',
              maxLength: 200,
              validator: validateRequired,
            ),
            _Pair(
              _Field(
                label: 'Número exterior',
                controller: _exterior,
                hint: 'Ej. 123',
                maxLength: 20,
              ),
              _Field(
                label: 'Número interior',
                controller: _interior,
                hint: 'Ej. 4B',
                maxLength: 20,
              ),
            ),
            _Pair(
              _Field(
                label: 'Municipio',
                controller: _municipality,
                hint: 'Ej. Guadalajara',
                maxLength: 100,
                validator: validateRequired,
              ),
              _Field(
                label: 'Ciudad',
                controller: _city,
                hint: 'Ej. Guadalajara',
                maxLength: 100,
                validator: validateRequired,
              ),
            ),
            _Pair(
              _Field(
                label: 'Estado',
                controller: _state,
                hint: 'Ej. Jalisco',
                maxLength: 100,
                validator: validateRequired,
              ),
              _Field(
                label: 'Código postal',
                controller: _postalCode,
                hint: 'Ej. 44100',
                maxLength: 10,
                validator: validatePostalCode,
              ),
            ),
            _Field(
              label: 'País',
              controller: _country,
              hint: 'Ej. México',
              maxLength: 100,
              validator: validateRequired,
            ),
            if (error != null)
              Text(
                apiErrorMessage(
                  error,
                  _isEdit
                      ? 'No fue posible actualizar la sucursal.'
                      : 'No fue posible agregar la sucursal.',
                  forbidden: 'No tienes permiso para esta acción.',
                ),
                style: textTheme.bodyMedium?.copyWith(color: colors.danger),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair(this.first, this.second);

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoColumnsMinWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: CascaSpacing.space4),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    required this.maxLength,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CascaSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: CascaFontWeight.semibold),
          ),
          const SizedBox(height: CascaSpacing.space2),
          CascaInput(
            controller: controller,
            hintText: hint,
            maxLength: maxLength,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.next,
            validator: validator,
          ),
        ],
      ),
    );
  }
}
