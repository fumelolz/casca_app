import 'dart:convert';
import 'dart:typed_data';

import 'package:casca_app/app/theme/casca_theme.dart';
import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/storage/preferences_storage.dart';
import 'package:casca_app/features/printers/presentation/pages/printer_settings_page.dart';
import 'package:casca_app/features/printers/presentation/providers/printer_scan_provider.dart';
import 'package:casca_app/shared/ui/casca_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakePrinter implements DevicePrinter {
  final sent = <(String, String)>[];
  PrinterFailure? failure;

  @override
  bool get supported => true;

  @override
  PrinterTransport get transport => PrinterTransport.bluetooth;

  @override
  Stream<PrinterDevice> scan() {
    return Stream.value(const PrinterDevice(id: 'a1', name: 'RP425-1234'));
  }

  @override
  Future<void> send(String deviceId, Uint8List data) async {
    final failure = this.failure;
    if (failure != null) throw PrinterException(failure);
    sent.add((deviceId, utf8.decode(data)));
  }
}

class _MemoryStorage extends PreferencesStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(CascaButton, label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('busca, guarda la impresora e imprime la prueba', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final printer = _FakePrinter();
    final storage = _MemoryStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          devicePrinterProvider.overrideWithValue(printer),
          preferencesStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          theme: CascaTheme.light,
          home: const Scaffold(
            body: PrinterSettingsPage(initialTab: PrinterTab.labels),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CascaButton, 'Buscar impresoras'));
    await tester.pump();
    await tester.pump();
    await _tap(tester, 'Usar');
    await _tap(tester, 'Imprimir prueba');

    expect(storage.values[PreferencesStorage.labelPrinterKey], contains('a1'));
    expect(printer.sent.single.$1, 'a1');
    expect(printer.sent.single.$2, contains('Etiqueta de prueba'));
    expect(find.text('Se envió la etiqueta a la impresora.'), findsOneWidget);

    printer.failure = PrinterFailure.bluetoothOff;
    await _tap(tester, 'Imprimir prueba');

    expect(find.text(PrinterFailure.bluetoothOff.message), findsOneWidget);
  });
}
