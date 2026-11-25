import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/core/auth/auth_controller.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/data/models/product_detail_model.dart';
import 'package:casca_app/features/products/data/models/product_variant_model.dart';
import 'package:casca_app/features/products/data/photo_picker.dart';
import 'package:casca_app/features/products/domain/product_form_rules.dart';
import 'package:casca_app/features/products/domain/product_variant_rules.dart';
import 'package:casca_app/features/products/domain/product_variant_view_rules.dart';
import 'package:casca_app/features/products/presentation/providers/product_variant_actions_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/photo_source.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_fields.dart';
import 'package:casca_app/features/products/presentation/widgets/product_thumbnail.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

const String _newValue = '__nuevo__';
const double _photoSize = 96;
const int _maxBarcodeLength = 50;
const int _maxNameLength = 100;

class VariantFormModal extends ConsumerStatefulWidget {
  const VariantFormModal({super.key, required this.product, this.variant});

  final ProductDetailModel product;
  final ProductVariantModel? variant;

  @override
  ConsumerState<VariantFormModal> createState() => _VariantFormModalState();
}

class _VariantFormModalState extends ConsumerState<VariantFormModal> {
  final _formKey = GlobalKey<FormState>();

  ProductVariantModel? get _variant => widget.variant;
  bool get _isEdit => _variant != null;
  VariantSaleUnitModel? get _saleUnit => _variant?.saleUnit;

  late final List<VariantOptionGroup> _groups = buildOptionGroups(
    widget.product.variants,
  );
  late final List<String?> _choices = List.filled(_groups.length, null);
  late final List<TextEditingController> _newValues = [
    for (final _ in _groups) TextEditingController(),
  ];
  late final Map<String, TextEditingController> _optionValues = {
    for (final option in _variant?.options ?? const [])
      option.name: TextEditingController(text: option.value),
  };

  late final _name = TextEditingController(text: _variant?.displayName);
  final _optionName = TextEditingController();
  final _optionValue = TextEditingController();
  late final _price = _amount(_saleUnit?.price);
  late final _barcode = TextEditingController(text: _saleUnit?.barcode);
  late final _minimum = _amount(_variant?.minimumStock);
  late final _maximum = _amount(_variant?.maximumStock);

  ProductUnit _unit = ProductUnit.piece;
  bool _combine = false;
  bool _trackInventory = false;
  bool _choiceMissing = false;
  PickedPhoto? _photo;
  Object? _photoError;

  static TextEditingController _amount(double? value) {
    return TextEditingController(
      text: value == null ? '' : formatQuantity(value).replaceAll(',', ''),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _optionName,
      _optionValue,
      _price,
      _barcode,
      _minimum,
      _maximum,
      ..._newValues,
      ..._optionValues.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<OptionSelection> get _selection {
    if (_groups.isEmpty) {
      return [
        OptionSelection(
          name: _optionName.text.trim(),
          value: _optionValue.text.trim(),
        ),
      ];
    }
    return [
      for (final (index, group) in _groups.indexed)
        OptionSelection(
          name: group.name,
          createdNow: _choices[index] == _newValue,
          value: _choices[index] == _newValue
              ? _newValues[index].text.trim()
              : _choices[index] ?? '',
        ),
    ];
  }

  String? get _duplicatedMessage {
    final selection = _selection;
    if (_groups.isEmpty || selection.any((option) => option.value.isEmpty)) {
      return null;
    }
    final duplicated = findVariantByOptions(widget.product.variants, selection);
    if (duplicated == null) return null;
    return isVariantActive(duplicated)
        ? 'Ya existe una variante con esa combinación.'
        : 'Ya existe una variante inactiva con esa combinación. Actívala desde la lista.';
  }

  String? _required(String? value) {
    return (value?.trim() ?? '').isEmpty ? 'Este campo es obligatorio' : null;
  }

  Future<void> _pickPhoto() async {
    try {
      final photos = await pickPhotos(context, ref, limit: 1);
      if (!mounted || photos.isEmpty) return;
      setState(() {
        _photo = photos.first;
        _photoError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _photoError = error);
    }
  }

  Future<void> _save({required bool showsLimits}) async {
    final missingChoice = !_isEdit && _choices.contains(null);
    setState(() => _choiceMissing = missingChoice);
    final valid = _formKey.currentState!.validate();
    if (!valid || missingChoice) return;
    if (!_isEdit && _duplicatedMessage != null) return;

    final controller = ref.read(
      variantActionProvider((widget.product.id, VariantAction.form)).notifier,
    );
    final price = parseAmount(_price.text) ?? 0;
    final barcode = _barcode.text.trim().isEmpty ? null : _barcode.text.trim();
    final variant = _variant;
    final bool saved;

    if (variant != null) {
      saved = await controller.edit(
        VariantEdit(
          original: variant,
          displayName: _name.text,
          optionValues: {
            for (final entry in _optionValues.entries)
              entry.key: entry.value.text,
          },
          price: price,
          barcode: barcode,
          trackInventory: _trackInventory,
          limits: showsLimits
              ? (
                  minimum: parseAmount(_minimum.text) ?? 0,
                  maximum: parseAmount(_maximum.text),
                )
              : null,
          photo: _photo,
        ),
      );
    } else {
      final selection = _selection;
      Map<String, dynamic> build(List<OptionSelection> options, String? code) {
        return toNewVariant(
          options,
          unitOfMeasure: _unit.code,
          allowsDecimals: _unit.allowsDecimals,
          price: price,
          barcode: code,
        );
      }

      saved = await controller.add(
        VariantAddition(
          selection: selection,
          variants: [
            build(selection, barcode),
            if (_combine)
              for (final extra in buildExtraCombinations(
                widget.product.variants,
                selection,
              ))
                build(extra, null),
          ],
          photo: _photo,
        ),
      );
    }

    if (saved && mounted) Navigator.of(context).pop(true);
  }

  Widget _photoField() {
    final photo = _photo;

    return Row(
      spacing: CascaSpacing.space4,
      children: [
        ClipRRect(
          borderRadius: CascaRadius.md,
          child: SizedBox.square(
            dimension: _photoSize,
            child: ColoredBox(
              color: context.casca.backgroundHover,
              child: photo != null
                  ? Image.memory(photo.bytes, fit: BoxFit.cover)
                  : ProductPicture(image: _variant?.image),
            ),
          ),
        ),
        CascaButton(
          label: photo == null && _variant?.image == null
              ? 'Agregar foto'
              : 'Cambiar foto',
          variant: CascaButtonVariant.secondary,
          onPressed: _pickPhoto,
        ),
      ],
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLength = maxOptionValueLength,
  }) {
    return ProductField(
      label: label,
      child: CascaInput(
        controller: controller,
        hintText: hint,
        maxLength: maxLength,
        validator: _required,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  List<Widget> _editFields() {
    return [
      _textField(
        'Nombre de la variante',
        _name,
        hint: 'Ej. Roja',
        maxLength: _maxNameLength,
      ),
      for (final entry in _optionValues.entries)
        _textField(entry.key, entry.value),
      if (_optionValues.isNotEmpty)
        Text(
          'El cambio de un valor se aplica a todas las variantes que lo usan. Las ventas pasadas no cambian.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ];
  }

  List<Widget> _newFields() {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final errorStyle = textTheme.bodySmall?.copyWith(color: colors.danger);
    final duplicated = _duplicatedMessage;
    final extras = buildExtraCombinations(widget.product.variants, _selection);

    return [
      if (_groups.isEmpty) ...[
        _textField(
          'Opción',
          _optionName,
          hint: 'Ej. Color',
          maxLength: maxOptionNameLength,
        ),
        _textField('Valor', _optionValue, hint: 'Ej. Roja'),
      ] else
        for (final (index, group) in _groups.indexed) ...[
          ProductField(
            label: group.name,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CascaSelect<String>(
                  options: [
                    for (final value in group.values)
                      CascaSelectOption(value: value, label: value),
                    const CascaSelectOption(
                      value: _newValue,
                      label: 'Nuevo valor…',
                    ),
                  ],
                  value: _choices[index],
                  hintText: 'Selecciona un valor',
                  onChanged: (value) => setState(() {
                    _choices[index] = value;
                    _choiceMissing = false;
                  }),
                ),
                if (_choiceMissing && _choices[index] == null)
                  Text('Selecciona un valor', style: errorStyle),
              ],
            ),
          ),
          if (_choices[index] == _newValue)
            _textField(
              'Nuevo valor de ${group.name}',
              _newValues[index],
              hint: 'Ej. Verde',
            ),
        ],
      if (duplicated != null) Text(duplicated, style: errorStyle),
      if (extras.isNotEmpty)
        _CombinationsSwitch(
          value: _combine,
          count: extras.length,
          labels: [
            for (final extra in extras)
              extra.map((option) => option.value).join(' / '),
          ],
          onChanged: (value) => setState(() => _combine = value),
        ),
      ProductField(
        label: 'Unidad de medida',
        child: CascaSelect<ProductUnit>(
          options: [
            for (final unit in ProductUnit.values)
              CascaSelectOption(value: unit, label: unit.label),
          ],
          value: _unit,
          onChanged: (unit) => setState(() => _unit = unit),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(
      variantActionProvider((widget.product.id, VariantAction.form)),
    );
    final canManageInventory = ref.watch(
      authControllerProvider.select(
        (auth) => auth.session?.hasPermission('inventory.update') ?? false,
      ),
    );
    final showsLimits =
        canManageInventory && (_saleUnit?.affectsInventory ?? false);
    final canEnableInventory = _saleUnit?.affectsInventory == false;
    final error = state.error ?? _photoError;

    return CascaModal(
      title: _isEdit ? 'Editar variante' : 'Agregar variante',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(
          label: _isEdit ? 'Guardar cambios' : 'Agregar',
          loading: state.isLoading,
          onPressed: () => _save(showsLimits: showsLimits),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CascaSpacing.space4,
          children: [
            if (error != null)
              Text(
                apiErrorMessage(error, 'No fue posible guardar la variante.'),
                style: textTheme.bodyMedium?.copyWith(color: colors.danger),
              ),
            _photoField(),
            ...(_isEdit ? _editFields() : _newFields()),
            ProductField(
              label: 'Precio de venta',
              child: ProductAmountInput(
                controller: _price,
                hintText: '0.00',
                money: true,
                validator: validatePrice,
              ),
            ),
            ProductField(
              label: 'Código de barras',
              child: CascaInput(
                controller: _barcode,
                hintText: 'Opcional',
                maxLength: _maxBarcodeLength,
              ),
            ),
            if (showsLimits)
              ProductFieldRow(
                children: [
                  ProductField(
                    label: 'Stock mínimo',
                    child: ProductAmountInput(
                      controller: _minimum,
                      hintText: '0',
                      validator: validateOptionalAmount,
                    ),
                  ),
                  ProductField(
                    label: 'Stock máximo',
                    child: ProductAmountInput(
                      controller: _maximum,
                      hintText: 'Sin máximo',
                      validator: (value) => validateMaximumStock(
                        value,
                        minimumStock: parseAmount(_minimum.text) ?? 0,
                      ),
                    ),
                  ),
                ],
              ),
            if (canEnableInventory)
              Row(
                children: [
                  CascaCheckbox(
                    value: _trackInventory,
                    semanticLabel: 'Controlar el inventario de esta variante',
                    onChanged: (value) =>
                        setState(() => _trackInventory = value),
                  ),
                  Expanded(
                    child: Text(
                      'Controlar el inventario de esta variante',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CombinationsSwitch extends StatelessWidget {
  const _CombinationsSwitch({
    required this.value,
    required this.count,
    required this.labels,
    required this.onChanged,
  });

  final bool value;
  final int count;
  final List<String> labels;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(CascaSpacing.space3),
      decoration: BoxDecoration(
        borderRadius: CascaRadius.md,
        border: Border.all(color: value ? colors.primary : colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CascaCheckbox(
            value: value,
            semanticLabel: 'Generar combinaciones',
            onChanged: onChanged,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: CascaSpacing.space1,
              children: [
                Text(
                  'Generar combinaciones',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: CascaFontWeight.semibold,
                  ),
                ),
                Text(
                  'Se crearán $count ${count == 1 ? 'variante' : 'variantes'} más, además de esta:',
                  style: textTheme.bodySmall,
                ),
                Text(labels.join(', '), style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
