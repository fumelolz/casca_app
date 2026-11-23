import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_step_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: CascaTheme.light,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

void main() {
  testWidgets('en el primer paso de dos muestra 50 %', (tester) async {
    await tester.pumpWidget(
      _wrap(const CascaStepProgress(currentStep: 0, totalSteps: 2)),
    );

    expect(find.text('PASO 1 DE 2'), findsOneWidget);
    expect(find.text('50% completado'), findsOneWidget);
  });

  testWidgets('en el último paso muestra 100 %', (tester) async {
    await tester.pumpWidget(
      _wrap(const CascaStepProgress(currentStep: 1, totalSteps: 2)),
    );

    expect(find.text('PASO 2 DE 2'), findsOneWidget);
    expect(find.text('100% completado'), findsOneWidget);
  });

  testWidgets('dibuja un segmento por paso', (tester) async {
    await tester.pumpWidget(
      _wrap(const CascaStepProgress(currentStep: 0, totalSteps: 3)),
    );

    expect(find.byType(AnimatedContainer), findsNWidgets(3));
    expect(find.text('33% completado'), findsOneWidget);
  });
}
