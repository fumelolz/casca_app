import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/errors/api_error_message.dart';
import 'package:casca_app/features/products/presentation/providers/product_variant_actions_provider.dart';
import 'package:casca_app/features/products/presentation/widgets/product_form_fields.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:casca_app/shared/ui/casca_segmented_control.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum _PriceMode { fixed, percentage }

const double _minimumPercentage = -100;

class VariantPriceModal extends ConsumerStatefulWidget {
  const VariantPriceModal({
    super.key,
    required this.productId,
    required this.variantIds,
  });

  final String productId;
  final Set<String> variantIds;

  @override
  ConsumerState<VariantPriceModal> createState() => _VariantPriceModalState();
}

class _VariantPriceModalState extends ConsumerState<VariantPriceModal> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  _PriceMode _mode = _PriceMode.fixed;

  bool get _isPercentage => _mode == _PriceMode.percentage;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    final minimum = _isPercentage ? _minimumPercentage : 0;
    if (number == null) return 'Ingresa un número';
    return number < minimum
        ? 'No puede ser menor que ${minimum.toInt()}'
        : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amount.text.trim());
    final saved = await ref
        .read(
          variantActionProvider((widget.productId, VariantAction.prices))
              .notifier,
        )
        .changePrices(
          widget.variantIds,
          price: _isPercentage ? null : amount,
          percentage: _isPercentage ? amount : null,
        );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(
      variantActionProvider((widget.productId, VariantAction.prices)),
    );
    final error = state.error;
    final count = widget.variantIds.length;

    return CascaModal(
      title: 'Cambiar precios',
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
        ),
        CascaButton(
          label: 'Aplicar',
          loading: state.isLoading,
          onPressed: _save,
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
                apiErrorMessage(error, 'No fue posible cambiar los precios.'),
                style: textTheme.bodyMedium?.copyWith(color: colors.danger),
              ),
            Text(
              'Se cambiará el precio de $count '
              '${count == 1 ? 'variante' : 'variantes'}.',
              style: textTheme.bodyMedium,
            ),
            CascaSegmentedControl<_PriceMode>(
              segments: const [
                CascaSegment(value: _PriceMode.fixed, label: 'Precio fijo'),
                CascaSegment(value: _PriceMode.percentage, label: 'Porcentaje'),
              ],
              value: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            ProductField(
              label: _isPercentage ? 'Porcentaje' : 'Nuevo precio',
              child: CascaInput(
                controller: _amount,
                hintText: _isPercentage ? '0' : '0.00',
                prefixText: _isPercentage ? null : r'$',
                suffixText: _isPercentage ? '%' : null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                ],
                validator: _validate,
              ),
            ),
            if (_isPercentage)
              Text(
                'Usa un valor negativo para aplicar un descuento.',
                style: textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
