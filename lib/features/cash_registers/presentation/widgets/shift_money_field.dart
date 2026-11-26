import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

double? parseAmount(String text) => double.tryParse(text.trim());

String amountText(double? amount) => amount?.toStringAsFixed(2) ?? '';

class ShiftFieldLabel extends StatelessWidget {
  const ShiftFieldLabel(this.text, {super.key, required this.child});

  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space2,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontWeight: CascaFontWeight.semibold),
        ),
        child,
      ],
    );
  }
}

class ShiftMoneyInput extends StatelessWidget {
  const ShiftMoneyInput({
    super.key,
    required this.controller,
    this.enabled = true,
    this.autofocus = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool autofocus;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return CascaInput(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      hintText: '0.00',
      prefixText: r'$',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}
