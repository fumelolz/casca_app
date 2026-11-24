import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class CascaPopoverHandle {
  const CascaPopoverHandle({
    required this.isOpen,
    required this.toggle,
    required this.open,
    required this.close,
  });

  final bool isOpen;
  final VoidCallback toggle;
  final VoidCallback open;
  final VoidCallback close;
}

class CascaPopover extends StatefulWidget {
  const CascaPopover({
    super.key,
    required this.triggerBuilder,
    required this.panelBuilder,
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = const Offset(0, 4),
  });

  final Widget Function(BuildContext context, CascaPopoverHandle handle)
  triggerBuilder;
  final Widget Function(BuildContext context, VoidCallback close) panelBuilder;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;

  @override
  State<CascaPopover> createState() => _CascaPopoverState();
}

class _CascaPopoverState extends State<CascaPopover> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _focus = FocusNode();

  void _open() {
    if (_portal.isShowing) return;
    _portal.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _portal.isShowing) _focus.requestFocus();
    });
    setState(() {});
  }

  void _close() {
    if (!_portal.isShowing) return;
    _portal.hide();
    if (mounted) setState(() {});
  }

  void _toggle() => _portal.isShowing ? _close() : _open();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handle = CascaPopoverHandle(
      isOpen: _portal.isShowing,
      toggle: _toggle,
      open: _open,
      close: _close,
    );

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildPanel,
      child: CompositedTransformTarget(
        link: _link,
        child: widget.triggerBuilder(context, handle),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: widget.targetAnchor,
            followerAnchor: widget.followerAnchor,
            offset: widget.offset,
            child: Focus(
              focusNode: _focus,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  _close();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Material(
                type: MaterialType.transparency,
                child: widget.panelBuilder(context, _close),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
