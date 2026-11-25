import 'package:casca_app/app/theme/casca_radius.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:material_ui/material_ui.dart';

const Duration _pulseDuration = Duration(milliseconds: 900);
const double _minOpacity = 0.45;

class CascaSkeleton extends StatefulWidget {
  const CascaSkeleton({
    super.key,
    this.width,
    this.height = 12,
    this.borderRadius = CascaRadius.sm,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<CascaSkeleton> createState() => _CascaSkeletonState();
}

class _CascaSkeletonState extends State<CascaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pulseDuration,
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(Tween<double>(begin: _minOpacity, end: 1)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.casca.border,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}
