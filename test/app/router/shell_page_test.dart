import 'package:casca_app/app/router/shell_page.dart';
import 'package:casca_app/app/theme/casca_colors.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host({
  required Animation<double> animation,
  bool disableAnimations = false,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Theme(
      data: CascaTheme.light,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Builder(
          builder: (context) => shellTransition(
            context,
            animation,
            const AlwaysStoppedAnimation(0),
            const SizedBox(key: Key('page')),
          ),
        ),
      ),
    ),
  );
}

Finder get _cover => find.byWidgetPredicate(
  (widget) =>
      widget is ColoredBox && widget.color == CascaColors.light.background,
);

double _opacity(WidgetTester tester) {
  final fade = tester.widget<FadeTransition>(
    find.ancestor(
      of: find.byKey(const Key('page')),
      matching: find.byType(FadeTransition),
    ),
  );
  return fade.opacity.value;
}

Offset _offset(WidgetTester tester) {
  final slide = tester.widget<SlideTransition>(
    find.ancestor(
      of: find.byKey(const Key('page')),
      matching: find.byType(SlideTransition),
    ),
  );
  return slide.position.value;
}

void main() {
  testWidgets('al empezar la página es transparente y está un poco abajo', (
    tester,
  ) async {
    await tester.pumpWidget(_host(animation: const AlwaysStoppedAnimation(0)));

    expect(_opacity(tester), 0);
    expect(_offset(tester).dy, greaterThan(0));
  });

  testWidgets('desde el inicio tapa la pantalla anterior', (tester) async {
    await tester.pumpWidget(_host(animation: const AlwaysStoppedAnimation(0)));

    expect(
      find.ancestor(of: find.byType(FadeTransition), matching: _cover),
      findsOneWidget,
    );
  });

  testWidgets('a mitad de la transición está a medias', (tester) async {
    await tester.pumpWidget(
      _host(animation: const AlwaysStoppedAnimation(0.5)),
    );

    expect(_opacity(tester), allOf(greaterThan(0), lessThan(1)));
    expect(_offset(tester).dy, allOf(greaterThan(0), lessThan(0.015)));
  });

  testWidgets('al terminar es opaca y en su sitio', (tester) async {
    await tester.pumpWidget(_host(animation: const AlwaysStoppedAnimation(1)));

    expect(_opacity(tester), 1);
    expect(_offset(tester), Offset.zero);
  });

  testWidgets('con animaciones reducidas no hay transición', (tester) async {
    await tester.pumpWidget(
      _host(
        animation: const AlwaysStoppedAnimation(0.2),
        disableAnimations: true,
      ),
    );

    expect(find.byType(FadeTransition), findsNothing);
    expect(find.byType(SlideTransition), findsNothing);
    expect(find.byKey(const Key('page')), findsOneWidget);
    expect(_cover, findsOneWidget);
  });
}
