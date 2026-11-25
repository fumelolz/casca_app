import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const double _disabledOpacity = 0.7;
const double _actionSize = 28;
const double _actionIconSize = 18;

class CascaInput extends StatefulWidget {
  const CascaInput({
    super.key,
    this.controller,
    this.hintText,
    this.iconStart,
    this.password = false,
    this.clearable = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.autofocus = false,
    this.maxLength,
    this.lines = 1,
    this.inputFormatters,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.showErrorMessage = true,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? iconStart;
  final bool password;
  final bool clearable;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final int? maxLength;
  final int lines;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode autovalidateMode;
  final bool showErrorMessage;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<CascaInput> createState() => _CascaInputState();
}

class _CascaInputState extends State<CascaInput> {
  late final bool _ownsController;
  late final TextEditingController _controller;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.clearable) setState(() {});
  }

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  void _handleChanged(FormFieldState<String> state, String value) {
    state.didChange(value);
    widget.onChanged?.call(value);
  }

  void _clear(FormFieldState<String> state) {
    _controller.clear();
    _handleChanged(state, '');
  }

  bool get _showClear {
    return widget.clearable &&
        widget.enabled &&
        !widget.readOnly &&
        _controller.text.isNotEmpty;
  }

  Widget? _buildSuffix(FormFieldState<String> state) {
    final actions = [
      if (_showClear)
        _InputAction(
          label: 'Limpiar texto',
          asset: CascaIcons.xmark,
          onPressed: () => _clear(state),
        ),
      if (widget.password)
        _InputAction(
          label: _passwordVisible ? 'Ocultar contraseña' : 'Mostrar contraseña',
          asset: _passwordVisible ? CascaIcons.eyeSlash : CascaIcons.eye,
          onPressed: widget.enabled ? _togglePasswordVisibility : null,
        ),
    ];

    if (actions.isEmpty) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  Widget _buildField(BuildContext context, FormFieldState<String> state) {
    final theme = Theme.of(context);
    final colors = context.casca;
    final iconStart = widget.iconStart;
    final invalid = state.hasError;

    final field = TextField(
      controller: _controller,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: widget.password && !_passwordVisible,
      enableSuggestions: !widget.password,
      autocorrect: !widget.password,
      keyboardType:
          widget.keyboardType ??
          (widget.lines > 1 ? TextInputType.multiline : null),
      minLines: widget.password ? 1 : widget.lines,
      maxLines: widget.password ? 1 : widget.lines,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      autofocus: widget.autofocus,
      inputFormatters: [
        ...?widget.inputFormatters,
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      onChanged: (value) => _handleChanged(state, value),
      onSubmitted: widget.onFieldSubmitted,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: widget.hintText,
        fillColor: widget.enabled ? null : colors.surfaceHover,
        enabledBorder: invalid ? theme.inputDecorationTheme.errorBorder : null,
        focusedBorder: invalid
            ? theme.inputDecorationTheme.focusedErrorBorder
            : null,
        prefixIcon: iconStart == null
            ? null
            : SizedBox.square(
                dimension: CascaSpacing.space8,
                child: Center(child: CascaIcon(iconStart)),
              ),
        suffixIcon: _buildSuffix(state),
      ),
    );

    final errorText = state.errorText;
    final showMessage = invalid && widget.showErrorMessage && errorText != null;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        if (showMessage) ...[
          const SizedBox(height: CascaSpacing.space2),
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.danger),
          ),
        ],
      ],
    );

    if (widget.enabled) return content;
    return Opacity(opacity: _disabledOpacity, child: content);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => widget.validator?.call(_controller.text),
      autovalidateMode: widget.autovalidateMode,
      builder: (state) => _buildField(context, state),
    );
  }
}

class _InputAction extends StatelessWidget {
  const _InputAction({
    required this.label,
    required this.asset,
    required this.onPressed,
  });

  final String label;
  final String asset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(
          width: _actionSize,
          height: _actionSize,
        ),
        icon: CascaIcon(asset, size: _actionIconSize),
      ),
    );
  }
}
