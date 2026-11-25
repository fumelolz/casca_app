import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

const double _buttonSize = 44;

class CascaTableFooter extends StatelessWidget {
  const CascaTableFooter({
    super.key,
    required this.selectedCount,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChanged,
  });

  final int selectedCount;
  final int page;
  final int pageSize;
  final int? totalItems;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final total = totalItems;
    final paginated = total != null && onPageChanged != null && total > 0;
    final from = (page - 1) * pageSize + 1;
    final to = total == null
        ? 0
        : (page * pageSize < total ? page * pageSize : total);
    final lastPage = total == null ? 1 : (total / pageSize).ceil();

    return Container(
      height: _buttonSize,
      padding: const EdgeInsets.only(
        left: CascaSpacing.space4 + CascaSpacing.space2,
        right: CascaSpacing.space3,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedCount > 0 ? _selectedLabel(selectedCount) : '',
              style: textTheme.bodySmall,
            ),
          ),
          if (paginated) ...[
            Text('$from–$to de $total', style: textTheme.bodySmall),
            _PageButton(
              icon: CascaIcons.chevronLeft,
              label: 'Página anterior',
              onPressed: page > 1 ? () => onPageChanged!(page - 1) : null,
            ),
            Text('$page', style: textTheme.labelLarge),
            _PageButton(
              icon: CascaIcons.chevronRight,
              label: 'Página siguiente',
              onPressed: page < lastPage
                  ? () => onPageChanged!(page + 1)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  static String _selectedLabel(int count) {
    return count == 1 ? '1 seleccionado' : '$count seleccionados';
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: _buttonSize,
          height: _buttonSize,
          child: Center(
            child: CascaIcon(
              icon,
              size: CascaSpacing.space4,
              color: enabled ? colors.text : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
