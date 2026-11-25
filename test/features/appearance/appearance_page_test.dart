import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/appearance/theme_mode_controller.dart';
import 'package:casca_app/core/layout/sidebar_controller.dart';
import 'package:casca_app/core/storage/preferences_storage.dart';
import 'package:casca_app/features/appearance/presentation/pages/appearance_page.dart';
import 'package:casca_app/features/appearance/presentation/widgets/theme_option_card.dart';
import 'package:casca_app/shared/ui/casca_checkbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  double width = 1000,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: CascaTheme.light,
          darkTheme: CascaTheme.dark,
          themeMode: ref.watch(themeModeProvider),
          home: const Scaffold(body: AppearancePage()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Brightness _brightness(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(AppearancePage))).brightness;
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('empieza en Sistema', (tester) async {
    final container = await _pump(tester);

    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(find.byType(ThemeOptionCard), findsNWidgets(3));
  });

  testWidgets('elegir Oscuro cambia el tema y lo recuerda', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(_brightness(tester), Brightness.dark);
    expect(
      await PreferencesStorage().read(PreferencesStorage.themeModeKey),
      'dark',
    );
  });

  testWidgets('al abrir recupera el tema guardado', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      PreferencesStorage.themeModeKey: 'dark',
    });

    final container = await _pump(tester);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(_brightness(tester), Brightness.dark);
  });

  testWidgets('un valor desconocido se ignora', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      PreferencesStorage.themeModeKey: 'morado',
    });

    final container = await _pump(tester);

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('contraer el menú se guarda y se recupera', (tester) async {
    final container = await _pump(tester);

    await tester.tap(find.byType(CascaCheckbox));
    await tester.pumpAndSettle();

    expect(container.read(sidebarProvider).collapsed, isTrue);
    final restored = ProviderContainer();
    addTearDown(restored.dispose);
    restored.read(sidebarProvider);
    await tester.pumpAndSettle();
    expect(restored.read(sidebarProvider).collapsed, isTrue);
  });

  testWidgets('en teléfono no ofrece el menú lateral ni desborda', (
    tester,
  ) async {
    await _pump(tester, width: 360);

    expect(find.byType(CascaCheckbox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
