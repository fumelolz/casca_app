import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const Duration _enter = Duration(milliseconds: 240);
const Duration _exit = Duration(milliseconds: 160);
const Offset _enterOffset = Offset(0, 0.015);

Widget shellTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  Widget covering(Widget content) {
    return ColoredBox(color: context.casca.background, child: content);
  }

  if (MediaQuery.disableAnimationsOf(context)) return covering(child);

  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeIn,
  );

  return covering(
    FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: _enterOffset,
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    ),
  );
}

Page<void> shellPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _enter,
    reverseTransitionDuration: _exit,
    transitionsBuilder: shellTransition,
  );
}
