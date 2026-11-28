import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/features/products/domain/product_variant_rules.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_fields.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:material_ui/material_ui.dart';

const double _removeSize = 44;

class ProductVariantOptionEditor extends StatefulWidget {
  const ProductVariantOptionEditor({
    super.key,
    required this.option,
    required this.otherOptions,
    required this.onSave,
    required this.onRemove,
  });

  final VariantOption? option;
  final List<VariantOption> otherOptions;
  final ValueChanged<VariantOption> onSave;
  final VoidCallback onRemove;

  @override
  State<ProductVariantOptionEditor> createState() =>
      _ProductVariantOptionEditorState();
}

class _ProductVariantOptionEditorState
    extends State<ProductVariantOptionEditor> {
  late final _name = TextEditingController(text: widget.option?.name);
  late final List<TextEditingController> _values = [
    for (final value in widget.option?.values ?? const <String>[])
      TextEditingController(text: value),
    TextEditingController(),
  ];
  final _removed = <TextEditingController>[];
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, ..._values, ..._removed]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onValueChanged(TextEditingController controller) {
    setState(() {
      _error = null;
      if (controller == _values.last && controller.text.trim().isNotEmpty) {
        _values.add(TextEditingController());
      }
    });
  }

  void _removeValue(TextEditingController controller) {
    setState(() {
      _error = null;
      _values.remove(controller);
      _removed.add(controller);
    });
  }

  void _save() {
    final option = VariantOption(
      name: _name.text.trim(),
      values: [
        for (final controller in _values)
          if (controller.text.trim().isNotEmpty) controller.text.trim(),
      ],
    );
    final error = validateVariantOption(option, widget.otherOptions);
    if (error != null) return setState(() => _error = error);
    widget.onSave(option);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final error = _error;

    return Container(
      padding: const EdgeInsets.all(CascaSpacing.space4),
      decoration: BoxDecoration(
        borderRadius: CascaRadius.md,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductField(
            label: 'Nombre de la opción',
            child: CascaInput(
              controller: _name,
              hintText: 'Ej. Talla o Color',
              maxLength: maxOptionNameLength,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          const SizedBox(height: CascaSpacing.space4),
          ProductField(
            label: 'Valores de la opción',
            child: Column(
              children: [
                for (final controller in _values)
                  Padding(
                    key: ObjectKey(controller),
                    padding: const EdgeInsets.only(bottom: CascaSpacing.space2),
                    child: Row(
                      children: [
                        Expanded(
                          child: CascaInput(
                            controller: controller,
                            hintText: 'Agregar otro valor',
                            maxLength: maxOptionValueLength,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => _onValueChanged(controller),
                          ),
                        ),
                        if (controller != _values.last)
                          _RemoveButton(
                            onPressed: () => _removeValue(controller),
                          )
                        else
                          const SizedBox(width: _removeSize),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (error != null) ...[
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.danger),
            ),
            const SizedBox(height: CascaSpacing.space2),
          ],
          const SizedBox(height: CascaSpacing.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: CascaSpacing.space2,
            runSpacing: CascaSpacing.space2,
            children: [
              CascaButton(
                label: 'Eliminar',
                variant: CascaButtonVariant.dangerOutlined,
                onPressed: widget.onRemove,
              ),
              CascaButton(label: 'Listo', onPressed: _save),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Eliminar valor',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: _removeSize / 2,
        child: SizedBox.square(
          dimension: _removeSize,
          child: Center(
            child: CascaIcon(
              CascaIcons.trash,
              size: CascaSpacing.space5,
              color: context.casca.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
