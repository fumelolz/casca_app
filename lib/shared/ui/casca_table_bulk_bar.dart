import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_table_models.dart';
import 'package:material_ui/material_ui.dart';

const double cascaTableBulkBarHeight = 52;
const double _actionMinHeight = 44;

class CascaTableBulkBar extends StatelessWidget {
  const CascaTableBulkBar({
    super.key,
    required this.selectedCount,
    required this.actions,
  });

  final int selectedCount;
  final List<CascaTableBulkAction> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final count = selectedCount == 1
        ? '1 seleccionado'
        : '$selectedCount seleccionados';

    return Container(
      height: cascaTableBulkBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: CascaSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: CascaRadius.md,
        border: Border.all(color: colors.border),
        boxShadow: CascaShadows.md,
      ),
      child: Row(
        children: [
          Text(
            count,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: CascaFontWeight.semibold,
            ),
          ),
          const SizedBox(width: CascaSpacing.space3),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final action in actions) _BulkButton(action: action),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkButton extends StatelessWidget {
  const _BulkButton({required this.action});

  final CascaTableBulkAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final color = action.danger ? colors.danger : colors.text;

    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action.onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _actionMinHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CascaSpacing.space3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (action.icon != null) ...[
                  CascaIcon(
                    action.icon!,
                    size: CascaSpacing.space4,
                    color: color,
                  ),
                  const SizedBox(width: CascaSpacing.space1),
                ],
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: CascaFontWeight.medium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
