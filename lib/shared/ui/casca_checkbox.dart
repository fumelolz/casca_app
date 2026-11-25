import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

const double _boxSize = 18;
const double _tapSize = 44;
const double _iconSize = 14;

class CascaCheckbox extends StatelessWidget {
  const CascaCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool? value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final enabled = onChanged != null;
    final mixed = value == null;
    final checked = value ?? false;
    final filled = checked || mixed;
    final fill = filled ? colors.primary : colors.surface;
    final border = filled ? colors.primary : colors.textMuted;

    return Semantics(
      label: semanticLabel,
      checked: mixed ? null : checked,
      mixed: mixed,
      enabled: enabled,
      excludeSemantics: true,
      onTap: enabled ? () => onChanged!(!checked) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!checked) : null,
        child: SizedBox(
          width: _tapSize,
          height: _tapSize,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Container(
                width: _boxSize,
                height: _boxSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(CascaSpacing.space1),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: filled
                    ? CascaIcon(
                        mixed ? CascaIcons.minus : CascaIcons.check,
                        size: _iconSize,
                        color: colors.onPrimary,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
