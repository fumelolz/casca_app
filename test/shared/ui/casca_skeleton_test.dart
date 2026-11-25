import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app({required bool reduceMotion}) {
  return MaterialApp(
    theme: CascaTheme.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: const Scaffold(body: CascaSkeleton(width: 100)),
      ),
    ),
  );
}

void main() {
  testWidgets('late mientras se muestra', (tester) async {
    await tester.pumpWidget(_app(reduceMotion: false));

    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('con reducir movimiento queda fijo', (tester) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pumpAndSettle();

    expect(tester.hasRunningAnimations, isFalse);
  });
}
