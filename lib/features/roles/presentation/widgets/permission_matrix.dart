import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/features/roles/data/models/role_models.dart';
import 'package:casca_app/features/roles/domain/permission_rules.dart';
import 'package:casca_app/shared/ui/casca_card.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:casca_app/shared/ui/casca_filter_bar.dart';
import 'package:material_ui/material_ui.dart';

class PermissionMatrix extends StatefulWidget {
  const PermissionMatrix({
    super.key,
    required this.groups,
    required this.selected,
    required this.onChanged,
    this.readOnly = false,
  });

  final List<PermissionGroupModel> groups;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool readOnly;

  @override
  State<PermissionMatrix> createState() => _PermissionMatrixState();
}

class _PermissionMatrixState extends State<PermissionMatrix> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final visible = filterGroups(widget.groups, _search);
    final total = widget.selected.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CascaSpacing.space3,
      children: [
        CascaFilterBar(
          searchHint: 'Buscar permiso...',
          onSearchChanged: (term) => setState(() => _search = term),
        ),
        Text(
          total == 1
              ? '1 permiso seleccionado'
              : '$total permisos seleccionados',
          style: textTheme.bodySmall,
        ),
        if (visible.isEmpty)
          Text(
            'Ningún permiso coincide con la búsqueda.',
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
        for (final group in visible)
          _group(
            context,
            group,
            widget.groups.firstWhere((other) => other.key == group.key),
          ),
      ],
    );
  }

  Widget _group(
    BuildContext context,
    PermissionGroupModel shown,
    PermissionGroupModel whole,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.casca;
    final canToggleGroup = !widget.readOnly && grantableKeys(whole).isNotEmpty;
    final count = whole.permissions
        .where((permission) => widget.selected.contains(permission.key))
        .length;

    return CascaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: CascaSpacing.space3,
        vertical: CascaSpacing.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CascaCheckbox(
                value: groupValue(whole, widget.selected),
                semanticLabel: 'Todos los permisos de ${whole.label}',
                onChanged: canToggleGroup
                    ? (checked) => widget.onChanged(
                        setGroup(whole, widget.selected, checked: checked),
                      )
                    : null,
              ),
              Expanded(
                child: Text(
                  whole.label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: CascaFontWeight.semibold,
                  ),
                ),
              ),
              Text(
                '$count de ${whole.permissions.length}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
          Divider(height: 1, color: colors.border),
          for (final permission in shown.permissions)
            Row(
              children: [
                CascaCheckbox(
                  value: widget.selected.contains(permission.key),
                  semanticLabel: permission.description,
                  onChanged: widget.readOnly || !permission.grantable
                      ? null
                      : (checked) => widget.onChanged(
                          togglePermission(
                            widget.selected,
                            permission.key,
                            checked: checked,
                          ),
                        ),
                ),
                Expanded(
                  child: Text(
                    permission.grantable || widget.readOnly
                        ? permission.description
                        : '${permission.description} (no puedes asignarlo)',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
