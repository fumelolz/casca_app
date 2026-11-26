import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/features/pos/data/models/pos_catalog_model.dart';
import 'package:casca_app/features/pos/domain/cart_rules.dart';
import 'package:casca_app/features/pos/domain/payment_rules.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:casca_app/shared/ui/casca_modal.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class PosQuantityModal extends StatefulWidget {
  const PosQuantityModal({super.key, required this.item});

  final PosCatalogItemModel item;

  @override
  State<PosQuantityModal> createState() => _PosQuantityModalState();
}

class _PosQuantityModalState extends State<PosQuantityModal> {
  final _quantity = TextEditingController();
  final _amount = TextEditingController();
  double? _value;

  void _quantityChanged(String text) {
    final typed = double.tryParse(text);
    final value = typed == null ? null : roundQuantity(typed);
    setState(() => _value = value != null && value > 0 ? value : null);
    _amount.text = _value == null
        ? ''
        : centsToText(toCents(estimateAmount(_value!, widget.item.price)));
  }

  void _amountChanged(String text) {
    final amount = double.tryParse(text);
    setState(
      () => _value = amount == null
          ? null
          : quantityForAmount(amount, widget.item.price),
    );
    _quantity.text = _value == null
        ? ''
        : formatQuantity(_value!).replaceAll(',', '');
  }

  void _confirm() {
    final value = _value;
    if (value != null) Navigator.of(context).pop(value);
  }

  @override
  void dispose() {
    _quantity.dispose();
    _amount.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required ValueChanged<String> onChanged,
    required int decimals,
    String? prefix,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space2,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        CascaInput(
          controller: controller,
          autofocus: autofocus,
          hintText: '0',
          prefixText: prefix,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp('^\\d*\\.?\\d{0,$decimals}'),
            ),
          ],
          onChanged: onChanged,
          onFieldSubmitted: (_) => _confirm(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CascaModal(
      title: widget.item.displayName,
      actions: [
        CascaButton(
          label: 'Cancelar',
          variant: CascaButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CascaButton(
          label: 'Agregar',
          onPressed: _value == null ? null : _confirm,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CascaSpacing.space4,
        children: [
          Text('Precio: ${formatMoney(widget.item.price)}'),
          _field(
            'Cantidad',
            _quantity,
            onChanged: _quantityChanged,
            decimals: 3,
            autofocus: true,
          ),
          _field(
            'Importe',
            _amount,
            onChanged: _amountChanged,
            decimals: 2,
            prefix: r'$',
          ),
        ],
      ),
    );
  }
}
