import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/core/printing/label_printer_settings.dart';
import 'package:casca_app/core/printing/product_label.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class LabelSizeCard extends ConsumerWidget {
  const LabelSizeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(labelPrinterSettingsProvider.select((s) => s.size));
    void resize({int? width, int? height}) {
      final current = ref.read(labelPrinterSettingsProvider).size;
      ref
          .read(labelPrinterSettingsProvider.notifier)
          .resize(
            LabelSize(
              widthMm: width ?? current.widthMm,
              heightMm: height ?? current.heightMm,
            ),
          );
    }

    return CascaCard(
      title: 'Tamaño de la etiqueta',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CascaSpacing.space3,
        children: [
          Expanded(
            child: _MillimetersField(
              key: ValueKey('width-${size.widthMm}'),
              label: 'Ancho',
              value: size.widthMm,
              isValid: LabelSize.isValidWidth,
              range: '${LabelSize.minWidthMm} a ${LabelSize.maxWidthMm} mm',
              onChanged: (width) => resize(width: width),
            ),
          ),
          Expanded(
            child: _MillimetersField(
              key: ValueKey('height-${size.heightMm}'),
              label: 'Alto',
              value: size.heightMm,
              isValid: LabelSize.isValidHeight,
              range: '${LabelSize.minHeightMm} a ${LabelSize.maxHeightMm} mm',
              onChanged: (height) => resize(height: height),
            ),
          ),
        ],
      ),
    );
  }
}

class _MillimetersField extends StatelessWidget {
  const _MillimetersField({
    super.key,
    required this.label,
    required this.value,
    required this.isValid,
    required this.range,
    required this.onChanged,
  });

  final String label;
  final int value;
  final bool Function(int? value) isValid;
  final String range;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space2,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        _MillimetersInput(
          value: value,
          isValid: isValid,
          range: range,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MillimetersInput extends StatefulWidget {
  const _MillimetersInput({
    required this.value,
    required this.isValid,
    required this.range,
    required this.onChanged,
  });

  final int value;
  final bool Function(int? value) isValid;
  final String range;
  final ValueChanged<int> onChanged;

  @override
  State<_MillimetersInput> createState() => _MillimetersInputState();
}

class _MillimetersInputState extends State<_MillimetersInput> {
  late final _controller = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_commitOnBlur);
  }

  @override
  void dispose() {
    _focus.removeListener(_commitOnBlur);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _commitOnBlur() {
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    final typed = int.tryParse(_controller.text);
    if (widget.isValid(typed) && typed != widget.value) {
      widget.onChanged(typed!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => _focus.unfocus(),
      child: CascaInput(
        controller: _controller,
        focusNode: _focus,
        suffixText: 'mm',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 3,
        validator: (text) =>
            widget.isValid(int.tryParse(text ?? '')) ? null : widget.range,
        onFieldSubmitted: (_) => _commit(),
      ),
    );
  }
}
