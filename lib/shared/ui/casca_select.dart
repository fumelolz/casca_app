import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const double _disabledOpacity = 0.7;
const double _menuGap = CascaSpacing.space1;
const double _menuPadding = CascaSpacing.space1;
const double _optionHeight = CascaSpacing.space8;
const double _badgeSize = 28;
const double _triggerImageSize = 20;
const double _menuMaxHeight = 320;

class CascaSelectOption<T> {
  const CascaSelectOption({
    required this.value,
    required this.label,
    this.icon,
    this.image,
  });

  final T value;
  final String label;
  final String? icon;
  final ImageProvider? image;
}

class CascaSelect<T> extends StatefulWidget {
  const CascaSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.iconStart,
    this.enabled = true,
    this.validator,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.showErrorMessage = true,
  });

  final List<CascaSelectOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String? hintText;
  final String? iconStart;
  final bool enabled;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode autovalidateMode;
  final bool showErrorMessage;

  @override
  State<CascaSelect<T>> createState() => _CascaSelectState<T>();
}

class _CascaSelectState<T> extends State<CascaSelect<T>> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _focus = FocusNode();
  final _triggerKey = GlobalKey();

  Size _triggerSize = Size.zero;
  bool _openAbove = false;
  double _menuHeight = _menuMaxHeight;
  FormFieldState<T>? _formState;

  bool get _open => _portal.isShowing;

  CascaSelectOption<T>? get _selected {
    for (final option in widget.options) {
      if (option.value == widget.value) return option;
    }
    return null;
  }

  void _openMenu(FormFieldState<T> state) {
    final box = _triggerKey.currentContext!.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final contentHeight =
        widget.options.length * _optionHeight + _menuPadding * 2;
    final wanted = contentHeight < _menuMaxHeight
        ? contentHeight
        : _menuMaxHeight;
    final below =
        media.size.height -
        media.viewInsets.bottom -
        (topLeft.dy + box.size.height) -
        _menuGap;
    final above = topLeft.dy - media.padding.top - _menuGap;

    setState(() {
      _formState = state;
      _triggerSize = box.size;
      _openAbove = below < wanted && above > below;
      final space = _openAbove ? above : below;
      _menuHeight = wanted < space ? wanted : space;
    });
    _portal.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _portal.isShowing) _focus.requestFocus();
    });
  }

  void _closeMenu() {
    if (!_open) return;
    _portal.hide();
    setState(() {});
  }

  void _pick(CascaSelectOption<T> option) {
    _formState?.didChange(option.value);
    widget.onChanged(option.value);
    _closeMenu();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CascaSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _open) _closeMenu();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: widget.value,
      validator: (_) => widget.validator?.call(widget.value),
      autovalidateMode: widget.autovalidateMode,
      builder: (state) => _buildField(context, state),
    );
  }

  Widget _buildField(BuildContext context, FormFieldState<T> state) {
    final theme = Theme.of(context);
    final colors = context.casca;
    final invalid = state.hasError;
    final selected = _selected;

    final decorator = InputDecorator(
      isEmpty: selected == null,
      isFocused: _open,
      decoration: InputDecoration(
        hintText: widget.hintText,
        enabledBorder: invalid ? theme.inputDecorationTheme.errorBorder : null,
        focusedBorder: invalid
            ? theme.inputDecorationTheme.focusedErrorBorder
            : null,
        prefixIcon: _prefix(selected),
        suffixIcon: SizedBox.square(
          dimension: CascaSpacing.space8,
          child: Center(
            child: CascaIcon(
              CascaIcons.chevronDown,
              size: CascaFontSize.sm,
              color: colors.textMuted,
            ),
          ),
        ),
      ),
      child: Text(
        selected?.label ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
    );

    final trigger = Semantics(
      button: true,
      enabled: widget.enabled,
      expanded: _open,
      label: widget.hintText,
      value: selected?.label,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled
              ? () => _open ? _closeMenu() : _openMenu(state)
              : null,
          child: ExcludeSemantics(child: decorator),
        ),
      ),
    );

    final errorText = state.errorText;
    final showMessage = invalid && widget.showErrorMessage && errorText != null;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverlayPortal(
          controller: _portal,
          overlayChildBuilder: _buildMenu,
          child: CompositedTransformTarget(
            link: _link,
            child: KeyedSubtree(key: _triggerKey, child: trigger),
          ),
        ),
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

  Widget? _prefix(CascaSelectOption<T>? selected) {
    final image = selected?.image;
    final icon = selected?.icon ?? widget.iconStart;

    if (image != null) {
      return SizedBox.square(
        dimension: CascaSpacing.space8,
        child: Center(
          child: ClipRRect(
            borderRadius: CascaRadius.sm,
            child: Image(
              image: image,
              width: _triggerImageSize,
              height: _triggerImageSize,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    if (icon == null) return null;
    return SizedBox.square(
      dimension: CascaSpacing.space8,
      child: Center(child: CascaIcon(icon)),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final colors = context.casca;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeMenu,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: _openAbove ? Alignment.topLeft : Alignment.bottomLeft,
          followerAnchor: _openAbove ? Alignment.bottomLeft : Alignment.topLeft,
          offset: Offset(0, _openAbove ? -_menuGap : _menuGap),
          child: Align(
            alignment: _openAbove ? Alignment.bottomLeft : Alignment.topLeft,
            child: SizedBox(
              width: _triggerSize.width,
              height: _menuHeight,
              child: Focus(
                focusNode: _focus,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    _closeMenu();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: CascaRadius.md,
                    border: Border.all(color: colors.border),
                    boxShadow: CascaShadows.lg,
                  ),
                  child: ClipRRect(
                    borderRadius: CascaRadius.md,
                    child: ListView(
                      padding: const EdgeInsets.all(_menuPadding),
                      children: [
                        for (final option in widget.options)
                          _OptionTile<T>(
                            option: option,
                            selected: option.value == widget.value,
                            onTap: () => _pick(option),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CascaSelectOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: CascaRadius.sm,
          hoverColor: colors.surfaceHover,
          child: Container(
            height: _optionHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: CascaSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: selected ? colors.surfaceHover : null,
              borderRadius: CascaRadius.sm,
            ),
            child: Row(
              children: [
                if (option.image != null || option.icon != null) ...[
                  _Leading(option: option),
                  const SizedBox(width: CascaSpacing.space3),
                ],
                Expanded(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: selected
                          ? CascaFontWeight.semibold
                          : CascaFontWeight.regular,
                    ),
                  ),
                ),
                if (selected)
                  CascaIcon(
                    CascaIcons.check,
                    size: CascaFontSize.sm,
                    color: colors.info,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Leading<T> extends StatelessWidget {
  const _Leading({required this.option});

  final CascaSelectOption<T> option;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final image = option.image;
    final icon = option.icon;

    return SizedBox.square(
      dimension: _badgeSize,
      child: image != null
          ? ClipRRect(
              borderRadius: CascaRadius.sm,
              child: Image(image: image, fit: BoxFit.cover),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colors.infoSoft,
                borderRadius: CascaRadius.sm,
              ),
              child: Center(
                child: CascaIcon(
                  icon!,
                  size: CascaFontSize.sm,
                  color: colors.info,
                ),
              ),
            ),
    );
  }
}
