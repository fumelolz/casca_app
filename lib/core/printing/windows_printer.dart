import 'dart:typed_data';

import 'package:casca_app/core/printing/device_printer.dart';
import 'package:casca_app/core/printing/print_spooler.dart';

class WindowsPrinter implements DevicePrinter {
  const WindowsPrinter(this._spooler);

  final PrintSpooler _spooler;

  @override
  bool get supported => true;

  @override
  PrinterTransport get transport => PrinterTransport.usb;

  @override
  Stream<PrinterDevice> scan() async* {
    for (final printer in _usbPrinters()) {
      yield PrinterDevice(id: printer.name, name: printer.name);
    }
  }

  @override
  Future<void> send(String deviceId, Uint8List data) async {
    final connected = _usbPrinters().any(
      (printer) => printer.name == deviceId && !printer.offline,
    );
    if (!connected) {
      throw const PrinterException(PrinterFailure.usbDisconnected);
    }
    _guard(() => _spooler.printRaw(deviceId, data));
  }

  List<SpoolerPrinter> _usbPrinters() {
    return _guard(
      () => _spooler
          .printers()
          .where((printer) => printer.port.toUpperCase().startsWith('USB'))
          .toList(),
    );
  }

  T _guard<T>(T Function() action) {
    try {
      return action();
    } catch (_) {
      throw const PrinterException(PrinterFailure.spooler);
    }
  }
}
