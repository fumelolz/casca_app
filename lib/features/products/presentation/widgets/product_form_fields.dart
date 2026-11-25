import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const double _rowMinWidth = 420;

class ProductField extends StatelessWidget {
  const ProductField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.casca.textSecondary,
            fontWeight: CascaFontWeight.medium,
          ),
        ),
        const SizedBox(height: CascaSpacing.space2),
        child,
      ],
    );
  }
}

class ProductFieldRow extends StatelessWidget {
  const ProductFieldRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < _rowMinWidth;
        return Flex(
          direction: stacked ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: stacked
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0)
                const SizedBox.square(dimension: CascaSpacing.space4),
              if (stacked) child else Expanded(child: child),
            ],
          ],
        );
      },
    );
  }
}

class ProductAmountInput extends StatelessWidget {
  const ProductAmountInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.enabled = true,
    this.money = false,
    this.unit,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final bool money;
  final String? unit;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return CascaInput(
      controller: controller,
      hintText: hintText,
      enabled: enabled,
      prefixText: money ? r'$' : null,
      suffixText: unit,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textInputAction: TextInputAction.next,
      validator: validator,
    );
  }
}
