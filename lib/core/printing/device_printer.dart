import 'package:casca_app/core/printing/ble_printer.dart';
import 'package:casca_app/core/printing/win32_print_spooler_stub.dart'
    if (dart.library.ffi) 'package:casca_app/core/printing/win32_print_spooler.dart';
import 'package:casca_app/core/printing/windows_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrinterDevice {
  const PrinterDevice({required this.id, required this.name});

  final String id;
  final String name;
}

enum PrinterTransport { bluetooth, usb }

enum PrinterFailure {
  unsupported('Este dispositivo no permite imprimir etiquetas.'),
  permission('Permite el acceso a Bluetooth en los ajustes del dispositivo.'),
  bluetoothOff('Enciende el Bluetooth e inténtalo de nuevo.'),
  connection(
    'No se pudo imprimir. Revisa que la impresora esté encendida, cerca y '
    'sin otra app conectada.',
  ),
  notPrinter('El dispositivo elegido no acepta impresiones.'),
  usbDisconnected('Conecta la impresora por USB y enciéndela.'),
  spooler(
    'Windows no pudo imprimir. Revisa la impresora e inténtalo de nuevo.',
  );

  const PrinterFailure(this.message);

  final String message;
}

class PrinterException implements Exception {
  const PrinterException(this.failure);

  final PrinterFailure failure;
}

String printerErrorMessage(Object error) {
  return error is PrinterException
      ? error.failure.message
      : PrinterFailure.connection.message;
}

abstract class DevicePrinter {
  bool get supported;

  PrinterTransport get transport;

  Stream<PrinterDevice> scan();

  Future<void> send(String deviceId, Uint8List data);
}

final devicePrinterProvider = Provider<DevicePrinter>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    return WindowsPrinter(createPrintSpooler());
  }
  return BlePrinter();
});
