import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/formatters/number_formatters.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const double _height = 40;
const double _fieldWidth = 52;

class CascaQuantityStepper extends StatefulWidget {
  const CascaQuantityStepper({
    super.key,
    required this.value,
    required this.subject,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
    this.decimals = false,
    this.removesOnDecrease = false,
  });

  final double value;
  final String subject;
  final double Function(double typed) onChanged;
  final VoidCallback onDecrease;
  final VoidCallback? onIncrease;
  final bool decimals;
  final bool removesOnDecrease;

  @override
  State<CascaQuantityStepper> createState() => _CascaQuantityStepperState();
}

class _CascaQuantityStepperState extends State<CascaQuantityStepper> {
  late final _controller = TextEditingController(text: _format(widget.value));
  bool _focused = false;

  static String _format(double value) {
    return formatQuantity(value).replaceAll(',', '');
  }

  void _sync() {
    final text = _format(widget.value);
    if (_controller.text != text) _controller.text = text;
  }

  void _changed(String text) {
    final typed = double.tryParse(text);
    if (typed == null || typed <= 0) return;
    final accepted = widget.onChanged(typed);
    if (accepted < typed) _controller.text = _format(accepted);
  }

  @override
  void didUpdateWidget(CascaQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focused && oldWidget.value == widget.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final typed = double.tryParse(_controller.text);
      if (!_focused || typed != widget.value) _sync();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final subject = widget.subject;
    const border = InputBorder.none;

    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: CascaRadius.xl,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            label: widget.removesOnDecrease
                ? 'Quitar $subject'
                : 'Disminuir cantidad de $subject',
            icon: widget.removesOnDecrease
                ? CascaIcons.trash
                : CascaIcons.minus,
            onPressed: widget.onDecrease,
          ),
          SizedBox(
            width: _fieldWidth,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onFocusChange: (focused) {
                _focused = focused;
                if (!focused) _sync();
              },
              child: Semantics(
                label: 'Cantidad de $subject',
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: CascaFontWeight.semibold),
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: widget.decimals,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(widget.decimals ? r'[0-9.]' : r'[0-9]'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    filled: false,
                    isCollapsed: true,
                    constraints: BoxConstraints(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: CascaSpacing.space2,
                    ),
                    border: border,
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                  onChanged: _changed,
                ),
              ),
            ),
          ),
          _StepButton(
            label: 'Aumentar cantidad de $subject',
            icon: CascaIcons.plus,
            onPressed: widget.onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: _height / 2,
        child: SizedBox.square(
          dimension: _height - 2,
          child: Center(
            child: CascaIcon(
              icon,
              size: CascaSpacing.space4,
              color: onPressed == null ? colors.border : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
