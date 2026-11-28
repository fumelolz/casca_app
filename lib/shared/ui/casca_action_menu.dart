import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_shadows.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_popover.dart';
import 'package:material_ui/material_ui.dart';

const double _menuMinWidth = 192;
const double _itemHeight = CascaSpacing.space8;
const double _itemIconSize = CascaFontSize.md;
const double _hoverOpacity = 0.06;
const double _pressedOpacity = 0.1;

class CascaActionMenuItem {
  const CascaActionMenuItem({
    required this.id,
    required this.label,
    required this.onSelected,
    this.icon,
    this.danger = false,
    this.disabled = false,
  });

  final String id;
  final String label;
  final VoidCallback onSelected;
  final String? icon;
  final bool danger;
  final bool disabled;
}

class CascaActionMenuSection {
  const CascaActionMenuSection({required this.items, this.title});

  final String? title;
  final List<CascaActionMenuItem> items;
}

class CascaActionMenu extends StatelessWidget {
  const CascaActionMenu({
    super.key,
    required this.sections,
    required this.semanticLabel,
    required this.child,
  });

  final List<CascaActionMenuSection> sections;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CascaPopover(
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      triggerBuilder: (context, handle) => Semantics(
        button: true,
        label: semanticLabel,
        expanded: handle.isOpen,
        excludeSemantics: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: handle.toggle,
            child: child,
          ),
        ),
      ),
      panelBuilder: (context, close) => _MenuPanel(
        label: semanticLabel,
        sections: sections,
        onSelected: (item) {
          close();
          item.onSelected();
        },
      ),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.label,
    required this.sections,
    required this.onSelected,
  });

  final String label;
  final List<CascaActionMenuSection> sections;
  final ValueChanged<CascaActionMenuItem> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: label,
      child: Container(
        constraints: const BoxConstraints(minWidth: _menuMinWidth),
        padding: const EdgeInsets.all(CascaSpacing.space1),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: CascaRadius.sm,
          border: Border.all(color: colors.border),
          boxShadow: CascaShadows.lg,
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      vertical: CascaSpacing.space1,
                    ),
                    color: colors.border,
                  ),
                if (sections[i].title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CascaSpacing.space3,
                      CascaSpacing.space2,
                      CascaSpacing.space3,
                      CascaSpacing.space1,
                    ),
                    child: Text(
                      sections[i].title!.toUpperCase(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        fontSize: CascaFontSize.xs,
                        fontWeight: CascaFontWeight.medium,
                        letterSpacing: 0.48,
                      ),
                    ),
                  ),
                for (final item in sections[i].items)
                  _MenuItem(item: item, onTap: () => onSelected(item)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.item, required this.onTap});

  final CascaActionMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final icon = item.icon;
    final textColor = item.danger ? colors.danger : colors.text;
    final iconColor = item.danger ? colors.danger : colors.textSecondary;
    final tint = item.danger ? colors.danger : colors.text;

    return Semantics(
      button: true,
      enabled: !item.disabled,
      label: item.label,
      excludeSemantics: true,
      child: Opacity(
        opacity: item.disabled ? 0.5 : 1,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: item.disabled ? null : onTap,
            borderRadius: CascaRadius.sm,
            hoverColor: tint.withValues(alpha: _hoverOpacity),
            focusColor: tint.withValues(alpha: _hoverOpacity),
            highlightColor: tint.withValues(alpha: _pressedOpacity),
            splashFactory: NoSplash.splashFactory,
            child: Container(
              height: _itemHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: CascaSpacing.space3,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    SizedBox(
                      width: _itemIconSize,
                      child: Center(
                        child: CascaIcon(
                          icon,
                          size: _itemIconSize,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: CascaSpacing.space3),
                  ],
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontSize: CascaFontSize.sm,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
