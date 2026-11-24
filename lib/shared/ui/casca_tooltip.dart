import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_spacing.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/app/theme/casca_typography.dart';
import 'package:material_ui/material_ui.dart';

enum CascaTooltipPosition { top, bottom, left, right }

const double _gap = CascaSpacing.space2;
const double _maxWidth = 256;

class CascaTooltip extends StatefulWidget {
  const CascaTooltip({
    super.key,
    required this.message,
    required this.child,
    this.position = CascaTooltipPosition.top,
    this.disabled = false,
  });

  final String message;
  final Widget child;
  final CascaTooltipPosition position;
  final bool disabled;

  @override
  State<CascaTooltip> createState() => _CascaTooltipState();
}

class _CascaTooltipState extends State<CascaTooltip> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();

  (Alignment, Alignment, Offset) get _anchors {
    return switch (widget.position) {
      CascaTooltipPosition.top => (
        Alignment.topCenter,
        Alignment.bottomCenter,
        const Offset(0, -_gap),
      ),
      CascaTooltipPosition.bottom => (
        Alignment.bottomCenter,
        Alignment.topCenter,
        const Offset(0, _gap),
      ),
      CascaTooltipPosition.left => (
        Alignment.centerLeft,
        Alignment.centerRight,
        const Offset(-_gap, 0),
      ),
      CascaTooltipPosition.right => (
        Alignment.centerRight,
        Alignment.centerLeft,
        const Offset(_gap, 0),
      ),
    };
  }

  void _show() {
    if (widget.disabled || widget.message.isEmpty || _portal.isShowing) return;
    _portal.show();
  }

  void _hide() {
    if (_portal.isShowing) _portal.hide();
  }

  @override
  void didUpdateWidget(CascaTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled && _portal.isShowing) _hide();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildTooltip,
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (_) => _show(),
          onExit: (_) => _hide(),
          child: Listener(onPointerDown: (_) => _hide(), child: widget.child),
        ),
      ),
    );
  }

  Widget _buildTooltip(BuildContext context) {
    final colors = context.casca;
    final textTheme = Theme.of(context).textTheme;
    final (target, follower, offset) = _anchors;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topLeft,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: target,
          followerAnchor: follower,
          offset: offset,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              padding: const EdgeInsets.symmetric(
                horizontal: CascaSpacing.space2,
                vertical: CascaSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: colors.text,
                borderRadius: CascaRadius.sm,
              ),
              child: Text(
                widget.message,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.surface,
                  fontSize: CascaFontSize.xs,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
