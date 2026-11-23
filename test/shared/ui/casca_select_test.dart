import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/shared/ui/casca_icon.dart';
import 'package:casca_app/shared/ui/casca_select.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _options = [
  CascaSelectOption(
    value: 'abarrotes',
    label: 'Abarrotes y tienda',
    icon: CascaIcons.basketShopping,
  ),
  CascaSelectOption(
    value: 'ferreteria',
    label: 'Ferretería',
    icon: CascaIcons.screwdriverWrench,
  ),
  CascaSelectOption(value: 'otro', label: 'Otro'),
];

class _Host extends StatefulWidget {
  const _Host({
    this.initial,
    this.enabled = true,
    this.onChanged,
    this.formKey,
  });

  final String? initial;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final GlobalKey<FormState>? formKey;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CascaTheme.light,
      home: Scaffold(
        body: Form(
          key: widget.formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CascaSelect<String>(
              options: _options,
              value: _value,
              enabled: widget.enabled,
              hintText: 'Selecciona el tipo de negocio',
              validator: (value) => value == null ? 'Elige una opción' : null,
              onChanged: (value) {
                setState(() => _value = value);
                widget.onChanged?.call(value);
              },
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('sin valor muestra el placeholder', (tester) async {
    await tester.pumpWidget(const _Host());

    expect(find.text('Selecciona el tipo de negocio'), findsOneWidget);
  });

  testWidgets('con valor muestra su etiqueta', (tester) async {
    await tester.pumpWidget(const _Host(initial: 'ferreteria'));

    expect(find.text('Ferretería'), findsOneWidget);
  });

  testWidgets('al tocar abre las opciones y al elegir una la selecciona', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(_Host(onChanged: (value) => picked = value));

    await tester.tap(find.text('Selecciona el tipo de negocio'));
    await tester.pumpAndSettle();
    expect(find.text('Abarrotes y tienda'), findsOneWidget);
    expect(find.text('Otro'), findsOneWidget);

    await tester.tap(find.text('Ferretería'));
    await tester.pumpAndSettle();

    expect(picked, 'ferreteria');
    expect(find.text('Ferretería'), findsOneWidget);
    expect(find.text('Abarrotes y tienda'), findsNothing);
  });

  testWidgets('tocar fuera cierra el menú sin cambiar el valor', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(_Host(onChanged: (value) => picked = value));

    await tester.tap(find.text('Selecciona el tipo de negocio'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();

    expect(picked, isNull);
    expect(find.text('Abarrotes y tienda'), findsNothing);
  });

  testWidgets('deshabilitado no abre las opciones', (tester) async {
    await tester.pumpWidget(const _Host(enabled: false));

    await tester.tap(
      find.text('Selecciona el tipo de negocio'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('Abarrotes y tienda'), findsNothing);
  });

  testWidgets('el validator muestra su mensaje dentro de un Form', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(_Host(formKey: formKey));

    formKey.currentState!.validate();
    await tester.pump();

    expect(find.text('Elige una opción'), findsOneWidget);
  });

  testWidgets('Escape cierra el menú', (tester) async {
    await tester.pumpWidget(const _Host());

    await tester.tap(find.text('Selecciona el tipo de negocio'));
    await tester.pumpAndSettle();
    expect(find.text('Otro'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Otro'), findsNothing);
  });

  testWidgets('el menú tiene el ancho del campo y queda debajo', (
    tester,
  ) async {
    await tester.pumpWidget(const _Host());
    final trigger = tester.getRect(find.byType(InputDecorator));

    await tester.tap(find.text('Selecciona el tipo de negocio'));
    await tester.pumpAndSettle();
    final option = tester.getRect(find.text('Abarrotes y tienda'));

    expect(option.top, greaterThan(trigger.bottom));
    expect(option.left, greaterThanOrEqualTo(trigger.left));
    expect(option.right, lessThanOrEqualTo(trigger.right));
  });

  testWidgets('acepta una imagen en lugar de un icono', (tester) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: CascaTheme.light,
        home: Scaffold(
          body: CascaSelect<String>(
            options: [
              CascaSelectOption(
                value: 'x',
                label: 'Con imagen',
                image: MemoryImage(bytes),
              ),
            ],
            value: 'x',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
  });
}
