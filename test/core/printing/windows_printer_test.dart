import 'dart:typed_data';

import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/printing/print_spooler.dart';
import 'package:casca_app/core/printing/windows_printer.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSpooler implements PrintSpooler {
  final printed = <String>[];

  @override
  List<SpoolerPrinter> printers() {
    return const [
      SpoolerPrinter(name: 'RP425', port: 'USB003'),
      SpoolerPrinter(name: 'POS-80C', port: 'USB001', offline: true),
      SpoolerPrinter(name: 'PDF', port: 'PORTPROMPT:'),
    ];
  }

  @override
  void printRaw(String printerName, Uint8List data) {
    printed.add(printerName);
  }
}

void main() {
  test('solo descubre las impresoras instaladas por USB', () async {
    final found = await WindowsPrinter(_FakeSpooler()).scan().toList();

    expect(found.map((printer) => printer.name), ['RP425', 'POS-80C']);
  });

  test('imprime solo si la impresora está conectada', () async {
    final spooler = _FakeSpooler();
    final printer = WindowsPrinter(spooler);

    await printer.send('RP425', Uint8List(1));

    await expectLater(
      printer.send('POS-80C', Uint8List(1)),
      throwsA(
        isA<PrinterException>().having(
          (error) => error.failure,
          'failure',
          PrinterFailure.usbDisconnected,
        ),
      ),
    );
    expect(spooler.printed, ['RP425']);
  });
}
