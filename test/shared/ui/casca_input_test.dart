import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_input.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: CascaTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

bool _obscured(WidgetTester tester) {
  return tester.widget<EditableText>(find.byType(EditableText)).obscureText;
}

void main() {
  testWidgets('muestra el placeholder y el ícono inicial', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const CascaInput(
          hintText: 'Ingresa tu correo',
          iconStart: CascaIcons.envelope,
        ),
      ),
    );

    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.byType(CascaIcon), findsOneWidget);
  });

  testWidgets('el ícono inicial mide 16 y no se estira al campo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CascaInput(iconStart: CascaIcons.envelope)),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(SvgPicture)).height, 16);
  });

  testWidgets('la contraseña empieza oculta y el ojo la muestra', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const CascaInput(password: true)));

    expect(_obscured(tester), isTrue);

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(_obscured(tester), isFalse);

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(_obscured(tester), isTrue);
  });

  testWidgets('clearable muestra la x solo con texto y limpia al tocarla', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? lastChange;

    await tester.pumpWidget(
      _wrap(
        CascaInput(
          controller: controller,
          clearable: true,
          onChanged: (value) => lastChange = value,
        ),
      ),
    );

    expect(find.byType(IconButton), findsNothing);

    await tester.enterText(find.byType(TextField), 'hola');
    await tester.pump();

    expect(find.byType(IconButton), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(lastChange, '');
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('muestra el error del validator dentro de un Form', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _wrap(
        Form(
          key: formKey,
          child: CascaInput(
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Campo obligatorio' : null,
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('Campo obligatorio'), findsOneWidget);
  });

  testWidgets(
    'showErrorMessage false oculta el texto y conserva el borde rojo',
    (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        _wrap(
          Form(
            key: formKey,
            child: CascaInput(
              showErrorMessage: false,
              validator: (_) => 'Campo obligatorio',
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      final errorBorder = CascaTheme.light.inputDecorationTheme.errorBorder;

      expect(find.text('Campo obligatorio'), findsNothing);
      expect(decorator.decoration.enabledBorder, errorBorder);
      expect(tester.getSize(find.byType(CascaInput)).height, 40);
    },
  );

  testWidgets('con showErrorMessage el error agrega alto bajo el campo', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      _wrap(
        Form(
          key: formKey,
          child: CascaInput(validator: (_) => 'Campo obligatorio'),
        ),
      ),
    );

    formKey.currentState!.validate();
    await tester.pump();

    expect(tester.getSize(find.byType(CascaInput)).height, greaterThan(40));
  });

  testWidgets('deshabilitado no permite escribir', (tester) async {
    await tester.pumpWidget(_wrap(const CascaInput(enabled: false)));

    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.enabled, isFalse);
  });
}
