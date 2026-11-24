import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:material_ui/material_ui.dart';

class TopbarIconButton extends StatefulWidget {
  const TopbarIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.borderless = false,
    this.badge,
    this.prominent = false,
  });

  static const double defaultSize = 32;
  static const double prominentSize = 44;

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool borderless;
  final int? badge;
  final bool prominent;

  @override
  State<TopbarIconButton> createState() => _TopbarIconButtonState();
}

class _TopbarIconButtonState extends State<TopbarIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.casca;
    final raised = _hovered || widget.active;
    final badge = widget.badge;

    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: widget.prominent
                    ? TopbarIconButton.prominentSize
                    : TopbarIconButton.defaultSize,
                height: widget.prominent
                    ? TopbarIconButton.prominentSize
                    : TopbarIconButton.defaultSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: raised ? colors.surfaceHover : null,
                  borderRadius: CascaRadius.md,
                  border: Border.all(
                    color: widget.borderless
                        ? Colors.transparent
                        : colors.border,
                  ),
                ),
                child: CascaIcon(
                  widget.icon,
                  size: widget.prominent ? CascaFontSize.lg : CascaFontSize.sm,
                  color: raised || widget.prominent
                      ? colors.text
                      : colors.textSecondary,
                ),
              ),
              if (badge != null && badge > 0)
                Positioned(
                  top: widget.prominent ? 4 : -6,
                  right: widget.prominent ? 4 : -6,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 17.6,
                      minHeight: 17.6,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.warning,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                    child: Text(
                      '$badge',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onPrimary,
                        fontSize: 10.4,
                        fontWeight: CascaFontWeight.semibold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
